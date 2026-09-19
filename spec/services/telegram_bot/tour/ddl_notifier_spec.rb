# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramBot::Tour::DdlNotifier do
  def build_league
    tournament = instance_double(Tournament, icon: '🏆', code: 'EPL')
    instance_double(League, tournament: tournament)
  end

  def build_user(locale: 'uk', time_zone: 'Europe/Kyiv', local_time: '21:00')
    instance_double(User, locale: locale, time_zone: time_zone, local_time: local_time)
  end

  def build_tour(league:, number: 7, deadline: 3.hours.from_now)
    tournament_round = instance_double(TournamentRound, deadline: deadline)
    instance_double(Tour, number: number, league: league, tournament_round: tournament_round)
  end

  def build_team(user:, tour:, lineup_present:)
    lineups = instance_double(ActiveRecord::Associations::CollectionProxy)
    allow(lineups).to receive(:exists?).with(tour: tour).and_return(lineup_present)
    instance_double(Team, user: user, lineups: lineups)
  end

  def stub_common_dependencies(tour)
    allow(Rails.application.routes.url_helpers).to receive(:tour_url).with(tour).and_return('https://fanta.test/tours/7')
    allow(I18n).to receive(:t).and_return('message')
    allow(TelegramBot::Sender).to receive(:call).and_return(true)
  end

  def build_case(user:, lineup_present:, deadline: 3.hours.from_now)
    tour = build_tour(league: build_league, deadline: deadline)
    team = build_team(user: user, tour: tour, lineup_present: lineup_present)
    stub_common_dependencies(tour)
    notification = instance_double(Notification, team: team, notifiable: tour)

    { notifier: described_class.new(notification), user: user }
  end

  def expect_i18n_payload(locale:, deadline:, time_zone:)
    expect(I18n).to have_received(:t).with(
      'telegram.notifier.tour.ddl',
      locale: locale,
      icon: '🏆',
      number: 7,
      deadline: deadline,
      time_zone: time_zone,
      url: 'https://fanta.test/tours/7',
      code: 'EPL'
    )
  end

  describe '#call' do
    it 'returns false when tour is nil' do
      notification = instance_double(Notification, notifiable: nil, team: nil)

      expect(described_class.new(notification).call).to be(false)
    end

    it 'returns false when team has no user' do
      data = build_case(user: nil, lineup_present: false)

      expect(data[:notifier].call).to be(false)
    end

    it 'does not call sender when team has no user' do
      data = build_case(user: nil, lineup_present: false)
      data[:notifier].call

      expect(TelegramBot::Sender).not_to have_received(:call)
    end

    # Checked at send time as well: a manager who set his lineup after the reminder was queued has
    # nothing left to be reminded about.
    it 'does not call sender when lineup already exists' do
      data = build_case(user: build_user, lineup_present: true)
      data[:notifier].call

      expect(TelegramBot::Sender).not_to have_received(:call)
    end

    # The queue can hold a reminder past the deadline it warns about; arriving then it is worse
    # than silence.
    it 'does not call sender when the deadline has already passed' do
      data = build_case(user: build_user, lineup_present: false, deadline: 5.minutes.ago)
      data[:notifier].call

      expect(TelegramBot::Sender).not_to have_received(:call)
    end

    it 'calls i18n with expected payload for eligible team' do
      data = build_case(user: build_user, lineup_present: false)
      data[:notifier].call

      expect_i18n_payload(locale: :uk, deadline: '21:00', time_zone: 'Europe/Kyiv')
    end

    it 'calls sender with user and message for eligible team' do
      data = build_case(user: build_user, lineup_present: false)
      data[:notifier].call

      expect(TelegramBot::Sender).to have_received(:call).with(data[:user], 'message', any_args)
    end

    it 'falls back to default locale when user locale is nil' do
      data = build_case(user: build_user(locale: nil, local_time: '18:00'), lineup_present: false)
      data[:notifier].call

      expect(I18n).to have_received(:t).with('telegram.notifier.tour.ddl', hash_including(locale: :en))
    end

    it 'falls back to default time zone when user time_zone is nil' do
      data = build_case(user: build_user(time_zone: nil, local_time: '18:00'), lineup_present: false)
      data[:notifier].call

      expect(I18n).to have_received(:t).with(
        'telegram.notifier.tour.ddl', hash_including(time_zone: User::DEFAULT_TIME_ZONE)
      )
    end
  end
end

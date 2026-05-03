# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramBot::Tour::DdlNotifier do
  def build_league
    tournament = instance_double(Tournament, icon: '🏆', code: 'EPL')
    instance_double(League, tournament: tournament)
  end

  def build_user(locale: 'uk', time_zone: 'Europe/Kyiv', local_time: '21:00')
    instance_double(
      User,
      locale: locale,
      time_zone: time_zone,
      local_time: local_time
    )
  end

  def build_tour(league:, teams:, number: 7)
    tournament_round = instance_double(TournamentRound, deadline: Time.zone.parse('2026-02-07 18:00:00'))
    instance_double(
      Tour,
      number: number,
      league: league,
      tournament_round: tournament_round,
      teams: teams
    )
  end

  def build_team(user:, tour:, lineup_present:)
    lineups_assoc = instance_double(ActiveRecord::Associations::CollectionProxy)
    lineup = lineup_present ? instance_double(Lineup) : nil
    allow(lineups_assoc).to receive(:find_by).with(tour: tour).and_return(lineup)
    instance_double(Team, user: user, lineups: lineups_assoc)
  end

  def stub_common_dependencies(tour)
    allow(Rails.application.routes.url_helpers).to receive(:tour_url).with(tour).and_return('https://fanta.test/tours/7')
    allow(I18n).to receive(:t).and_return('message')
    allow(TelegramBot::Sender).to receive(:call).and_return(true)
  end

  def build_case(user:, lineup_present:)
    tour = build_tour(league: build_league, teams: [])
    team = build_team(user: user, tour: tour, lineup_present: lineup_present)
    allow(tour).to receive(:teams).and_return([team])
    stub_common_dependencies(tour)
    { notifier: described_class.new(tour), user: user }
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

  def expect_default_locale
    expect(I18n).to have_received(:t).with(
      'telegram.notifier.tour.ddl',
      hash_including(locale: :en)
    )
  end

  def expect_default_time_zone
    expect(I18n).to have_received(:t).with(
      'telegram.notifier.tour.ddl',
      hash_including(time_zone: User::DEFAULT_TIME_ZONE)
    )
  end

  describe '#call' do
    it 'returns false when tour is nil' do
      expect(described_class.new(nil).call).to be(false)
    end

    it 'returns true when team has no user' do
      data = build_case(user: nil, lineup_present: false)
      expect(data[:notifier].call).to be(true)
    end

    it 'does not call sender when team has no user' do
      data = build_case(user: nil, lineup_present: false)
      data[:notifier].call
      expect(TelegramBot::Sender).not_to have_received(:call)
    end

    it 'does not call sender when lineup already exists' do
      data = build_case(user: build_user, lineup_present: true)
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
      expect(TelegramBot::Sender).to have_received(:call).with(data[:user], 'message')
    end

    it 'falls back to default locale when user locale is nil' do
      data = build_case(user: build_user(locale: nil, local_time: '18:00'), lineup_present: false)
      data[:notifier].call
      expect_default_locale
    end

    it 'falls back to default time zone when user time_zone is nil' do
      data = build_case(user: build_user(time_zone: nil, local_time: '18:00'), lineup_present: false)
      data[:notifier].call
      expect_default_time_zone
    end
  end
end

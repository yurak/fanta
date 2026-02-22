# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramBot::Tour::ClosedNotifier do
  def build_notifiable(league: nil)
    instance_double(
      'Tour',
      league: league,
      number: 1,
      tournament_round: instance_double('TournamentRound', deadline: Time.current)
    )
  end

  def build_league
    tournament = instance_double('Tournament', icon: '🏆', code: 'T')
    instance_double('League', name: 'League', tournament: tournament)
  end

  def build_user
    instance_double('User', locale: 'en', time_zone: 'UTC', local_time: 'Fri, Feb 7, 12:00')
  end

  def build_team(user:)
    instance_double('Team', user: user, human_name: 'Team')
  end

  def build_notification(team:, notifiable:)
    instance_double('Notification', team: team, notifiable: notifiable)
  end

  describe '#call' do
    it 'returns false when tour is nil' do
      notification = build_notification(team: build_team(user: build_user), notifiable: nil)
      expect(described_class.call(notification)).to be(false)
    end

    it 'returns false when league is nil' do
      tour = build_notifiable(league: nil)
      notification = build_notification(team: build_team(user: build_user), notifiable: tour)
      expect(described_class.call(notification)).to be(false)
    end

    it 'returns false when team is nil' do
      tour = build_notifiable(league: build_league)
      notification = build_notification(team: nil, notifiable: tour)
      expect(described_class.call(notification)).to be(false)
    end

    it 'returns false when user is nil' do
      tour = build_notifiable(league: build_league)
      notification = build_notification(team: build_team(user: nil), notifiable: tour)
      expect(described_class.call(notification)).to be(false)
    end

    it 'calls Sender service and returns true' do
      league = build_league
      tour = build_notifiable(league: league)
      user = build_user
      team = build_team(user: user)
      notification = build_notification(team: team, notifiable: tour)

      allow(Rails.application.routes.url_helpers).to receive(:tour_url).with(tour).and_return('http://test/tours/1')
      allow(I18n).to receive(:t).and_return('message')
      allow(TelegramBot::Sender).to receive(:call).and_return(true)

      result = described_class.call(notification)

      expect(result).to be(true)
    end
  end
end

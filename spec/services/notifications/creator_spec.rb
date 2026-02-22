# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::Creator do
  include ActiveSupport::Testing::TimeHelpers

  def build_tour_with_teams(user_teams_count: 2, userless_teams_count: 0)
    tour = create(:tour)
    league = tour.league

    user_teams_count.times { create(:team, league: league, user: create(:user)) }
    userless_teams_count.times { create(:team, league: league, user: nil) }

    tour
  end

  def create_notification(team:, tour:, kind:, status: Notification::PENDING, priority: :normal)
    create(:notification, team: team, notifiable: tour, kind: kind, status: status, priority: priority)
  end

  def notifications_scope(tour:, kind:)
    Notification.where(notifiable: tour, kind: kind)
  end

  describe '#initialize' do
    it 'raises for unknown kind' do
      expect { described_class.new(notifiable: build_tour_with_teams, kind: :unknown_kind) }
        .to raise_error(ArgumentError, %r{Invalid kind/priority enum value})
    end

    it 'raises for unknown priority' do
      expect { described_class.new(notifiable: build_tour_with_teams, kind: :tour_opened, priority: :super_high) }
        .to raise_error(ArgumentError, %r{Invalid kind/priority enum value})
    end
  end

  describe '#call' do
    it 'returns false when no eligible teams' do
      tour = build_tour_with_teams(user_teams_count: 0, userless_teams_count: 1)
      expect(described_class.call(notifiable: tour, kind: :tour_opened)).to be(false)
    end

    it 'creates notifications for user teams' do
      tour = build_tour_with_teams(user_teams_count: 2, userless_teams_count: 1)
      described_class.call(notifiable: tour, kind: :tour_opened)
      expect(notifications_scope(tour: tour, kind: :tour_opened).count).to eq(2)
    end

    it 'skips teams that were already notified' do
      tour = build_tour_with_teams(user_teams_count: 2)
      already_notified_team = tour.league.teams.first
      create_notification(team: already_notified_team, tour: tour, kind: :tour_opened)

      described_class.call(notifiable: tour, kind: :tour_opened)

      expect(notifications_scope(tour: tour, kind: :tour_opened).count).to eq(2)
    end

    it 'raises when kind is not supported by teams_for' do
      tour = build_tour_with_teams(user_teams_count: 1)
      expect { described_class.call(notifiable: tour, kind: :tour_ddl) }
        .to raise_error(ArgumentError, /does not know how to build teams/)
    end

    it 'calls insert_all! once' do
      tour = build_tour_with_teams(user_teams_count: 1)
      allow(Notification).to receive(:insert_all!).and_call_original
      described_class.call(notifiable: tour, kind: :tour_opened)
      expect(Notification).to have_received(:insert_all!).once
    end
  end
end

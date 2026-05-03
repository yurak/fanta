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

    it 'returns true on success' do
      tour = build_tour_with_teams(user_teams_count: 1)
      expect(described_class.call(notifiable: tour, kind: :tour_opened)).to be(true)
    end

    context 'with persisted notification' do
      let(:tour) { build_tour_with_teams(user_teams_count: 1) }
      let(:team) { tour.league.teams.first }

      before { described_class.call(notifiable: tour, kind: :tour_opened) }

      it 'associates with the correct team and notifiable' do
        expect(Notification.last).to have_attributes(team: team, notifiable: tour)
      end

      it 'stores kind, status and default priority' do
        expect(Notification.last).to have_attributes(kind: 'tour_opened', status: 'pending', priority: 'normal')
      end
    end

    it 'stores the specified priority' do
      tour = build_tour_with_teams(user_teams_count: 1)
      described_class.call(notifiable: tour, kind: :tour_opened, priority: :high)
      expect(Notification.last.priority).to eq('high')
    end

    context 'with auction_squad_complete kind' do
      let(:auction) { create(:auction) }
      let(:league) { auction.league }
      let(:alpha_team) { create(:team, :with_full_squad, league: league, user: create(:user)) }
      let(:beta_team) { create(:team, :with_full_squad, league: league, user: create(:user)) }
      let(:first_round) { create(:auction_round, auction: auction) }
      let(:second_round) { create(:auction_round, auction: auction) }

      before do
        create(:auction_bid, team: alpha_team, auction_round: first_round)
        create(:auction_bid, team: beta_team, auction_round: first_round)
        create(:auction_bid, team: alpha_team, auction_round: second_round)
        create(:auction_bid, team: beta_team, auction_round: second_round)
      end

      it 'creates notifications after first round' do
        described_class.call(notifiable: first_round, kind: :auction_squad_complete)

        expect(Notification.where(notifiable: first_round, kind: :auction_squad_complete).count).to eq(2)
      end

      it 'does not notify teams again after second round if already notified in first round' do
        described_class.call(notifiable: first_round, kind: :auction_squad_complete)
        described_class.call(notifiable: second_round, kind: :auction_squad_complete)

        expect(Notification.where(kind: :auction_squad_complete).count).to eq(2)
      end

      it 'does not create second round notifications for teams notified in first round' do
        described_class.call(notifiable: first_round, kind: :auction_squad_complete)
        described_class.call(notifiable: second_round, kind: :auction_squad_complete)

        expect(Notification.where(notifiable: second_round, kind: :auction_squad_complete).count).to eq(0)
      end
    end

    %i[tour_moderated tour_closed].each do |kind|
      it "creates notifications for :#{kind}" do
        tour = build_tour_with_teams(user_teams_count: 2)
        described_class.call(notifiable: tour, kind: kind)
        expect(notifications_scope(tour: tour, kind: kind).count).to eq(2)
      end
    end

    it 'does not block notification for a different kind' do
      tour = build_tour_with_teams(user_teams_count: 1)
      team = tour.league.teams.first
      create_notification(team: team, tour: tour, kind: :tour_opened)

      described_class.call(notifiable: tour, kind: :tour_moderated)

      expect(notifications_scope(tour: tour, kind: :tour_moderated).count).to eq(1)
    end

    it 'returns false when all teams are already notified' do
      tour = build_tour_with_teams(user_teams_count: 2)
      tour.league.teams.each { |team| create_notification(team: team, tour: tour, kind: :tour_opened) }

      expect(described_class.call(notifiable: tour, kind: :tour_opened)).to be(false)
    end
  end
end

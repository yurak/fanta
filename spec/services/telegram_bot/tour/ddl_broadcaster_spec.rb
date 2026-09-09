# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramBot::Tour::DdlBroadcaster do
  subject(:broadcaster) { described_class.new }

  let(:league) { create(:active_league) }

  before { allow(Notifications::Creator).to receive(:call) }

  context 'when there are no active leagues' do
    it 'does not record a notification' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when tour has no deadline' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: nil)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    it 'does not record a notification' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when deadline is more than 3 hours away' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 4.hours.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    it 'does not record a notification' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when deadline is within 3 hours' do
    let(:tour) do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 2.hours.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    before { tour }

    it 'records a tour_ddl notification' do
      broadcaster.call
      expect(Notifications::Creator).to have_received(:call).with(notifiable: tour, kind: :tour_ddl)
    end
  end

  context 'when deadline has already passed' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 1.hour.ago)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    it 'does not record a notification (past upper bound)' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when deadline is within 5 minutes' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 3.minutes.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    it 'does not record a notification' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when deadline is exactly 6 minutes away (just inside window)' do
    let(:tour) do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 6.minutes.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    before { tour }

    it 'records a notification' do
      broadcaster.call
      expect(Notifications::Creator).to have_received(:call).with(notifiable: tour, kind: :tour_ddl)
    end
  end

  context 'when tour is not in set_lineup status' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 1.hour.from_now)
      create(:locked_tour, league: league, tournament_round: tr)
    end

    it 'does not record a notification' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end
end

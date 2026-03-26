# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramBot::Tour::DdlBroadcaster do
  subject(:broadcaster) { described_class.new }

  let(:league) { create(:active_league) }

  before { allow(TelegramBot::Tour::DdlNotifier).to receive(:call) }

  context 'when there are no active leagues' do
    it 'does not call DdlNotifier' do
      broadcaster.call
      expect(TelegramBot::Tour::DdlNotifier).not_to have_received(:call)
    end
  end

  context 'when tour has no deadline' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: nil)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    it 'does not call DdlNotifier' do
      broadcaster.call
      expect(TelegramBot::Tour::DdlNotifier).not_to have_received(:call)
    end
  end

  context 'when deadline is more than 3 hours away' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 4.hours.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    it 'does not call DdlNotifier' do
      broadcaster.call
      expect(TelegramBot::Tour::DdlNotifier).not_to have_received(:call)
    end
  end

  context 'when deadline is within 3 hours' do
    let(:tour) do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 2.hours.from_now)
      create(:set_lineup_tour, league: league, tournament_round: tr)
    end

    before { tour }

    it 'calls DdlNotifier for the tour' do
      broadcaster.call
      expect(TelegramBot::Tour::DdlNotifier).to have_received(:call).with(tour)
    end

    context 'when deadline has already passed' do
      let(:tour) do
        tr = create(:tournament_round, tournament: league.tournament, deadline: 1.hour.ago)
        create(:set_lineup_tour, league: league, tournament_round: tr)
      end

      it 'calls DdlNotifier (still within window)' do
        broadcaster.call
        expect(TelegramBot::Tour::DdlNotifier).to have_received(:call).with(tour)
      end
    end
  end

  context 'when tour is not in set_lineup status' do
    before do
      tr = create(:tournament_round, tournament: league.tournament, deadline: 1.hour.from_now)
      create(:locked_tour, league: league, tournament_round: tr)
    end

    it 'does not call DdlNotifier' do
      broadcaster.call
      expect(TelegramBot::Tour::DdlNotifier).not_to have_received(:call)
    end
  end
end

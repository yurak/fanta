# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tours::DeadlineLocker do
  subject(:locker) { described_class.new(tour) }

  let(:league) { create(:active_league) }

  before { allow(Tours::Manager).to receive(:call) }

  context 'when tour has no deadline' do
    let(:tr)   { create(:tournament_round, tournament: league.tournament, deadline: nil) }
    let(:tour) { create(:set_lineup_tour, league: league, tournament_round: tr) }

    it { expect(locker.call).to be(false) }

    it 'does not call Tours::Manager' do
      locker.call
      expect(Tours::Manager).not_to have_received(:call)
    end
  end

  context 'when deadline has not passed yet' do
    let(:tr)   { create(:tournament_round, tournament: league.tournament, deadline: 1.hour.from_now) }
    let(:tour) { create(:set_lineup_tour, league: league, tournament_round: tr) }

    it { expect(locker.call).to be(false) }

    it 'does not call Tours::Manager' do
      locker.call
      expect(Tours::Manager).not_to have_received(:call)
    end
  end

  context 'when deadline has passed' do
    let(:tr)   { create(:tournament_round, tournament: league.tournament, deadline: 1.hour.ago) }
    let(:tour) { create(:set_lineup_tour, league: league, tournament_round: tr) }

    it { expect(locker.call).to be(true) }

    it 'calls Tours::Manager with LOCKED_STATUS' do
      locker.call
      expect(Tours::Manager).to have_received(:call).with(tour, Tours::Manager::LOCKED_STATUS)
    end
  end
end

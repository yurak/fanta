# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tours::AutoCloser do
  subject(:closer) { described_class.new(tournament_round) }

  let(:tournament_round) { create(:tournament_round, moderated_at: 18.hours.ago) }

  before { allow(Tours::Manager).to receive(:call) }

  context 'when not enough hours have passed' do
    let(:tournament_round) { create(:tournament_round, moderated_at: 17.hours.ago) }

    it { expect(closer.call).to be(false) }

    it 'does not call Tours::Manager' do
      closer.call
      expect(Tours::Manager).not_to have_received(:call)
    end

    it 'does not reset moderated_at' do
      closer.call
      expect(tournament_round.reload.moderated_at).not_to be_nil
    end
  end

  context 'when enough hours have passed' do
    it { expect(closer.call).to be(true) }

    it 'resets moderated_at to nil' do
      closer.call
      expect(tournament_round.reload.moderated_at).to be_nil
    end

    context 'with locked and postponed tours' do
      let(:locked_tour)    { create(:locked_tour, tournament_round: tournament_round) }
      let(:postponed_tour) { create(:postponed_tour, tournament_round: tournament_round) }

      before { [locked_tour, postponed_tour] }

      it 'closes locked tour' do
        closer.call
        expect(Tours::Manager).to have_received(:call).with(locked_tour, Tours::Manager::CLOSED_STATUS)
      end

      it 'closes postponed tour' do
        closer.call
        expect(Tours::Manager).to have_received(:call).with(postponed_tour, Tours::Manager::CLOSED_STATUS)
      end
    end

    context 'with a set_lineup tour (not locked or postponed)' do
      before { create(:set_lineup_tour, tournament_round: tournament_round) }

      it 'does not call Tours::Manager for it' do
        closer.call
        expect(Tours::Manager).not_to have_received(:call)
      end
    end

    context 'when there are no tours' do
      it 'does not call Tours::Manager' do
        closer.call
        expect(Tours::Manager).not_to have_received(:call)
      end
    end

    context 'when exactly MODERATED_HOURS have passed' do
      let(:tournament_round) { create(:tournament_round, moderated_at: TournamentRound::MODERATED_HOURS.hours.ago) }

      it { expect(closer.call).to be(true) }
    end
  end
end

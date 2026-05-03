# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tours::AutoInjector do
  subject(:injector) { described_class.new(tournament_round) }

  let(:tournament)       { create(:tournament, source: :fotmob) }
  let(:tournament_round) { create(:tournament_round, tournament: tournament, moderated_at: 6.hours.ago) }

  before do
    allow(Scores::Injectors::Fotmob).to receive(:call)
    allow(Scores::PositionMalus::Updater).to receive(:call)
    allow(Lineups::Updater).to receive(:call)
  end

  context 'when hours since moderated is in [6, 12, 17]' do
    it { expect(injector.call).to be(true) }

    it 'calls the injector' do
      injector.call
      expect(Scores::Injectors::Fotmob).to have_received(:call).with(tournament_round)
    end

    context 'with sofascore tournament' do
      let(:tournament) { create(:tournament, source: :sofascore) }

      before { allow(Scores::Injectors::Sofascore).to receive(:call) }

      it 'calls the sofascore injector' do
        injector.call
        expect(Scores::Injectors::Sofascore).to have_received(:call).with(tournament_round)
      end
    end

    context 'when 12 hours have passed' do
      let(:tournament_round) { create(:tournament_round, tournament: tournament, moderated_at: 12.hours.ago) }

      it { expect(injector.call).to be(true) }
    end

    context 'when 17 hours have passed' do
      let(:tournament_round) { create(:tournament_round, tournament: tournament, moderated_at: 17.hours.ago) }

      it { expect(injector.call).to be(true) }
    end
  end

  context 'when hours since moderated is not in [6, 12, 17]' do
    let(:tournament_round) { create(:tournament_round, tournament: tournament, moderated_at: 5.hours.ago) }

    it { expect(injector.call).to be(false) }

    it 'does not call the injector' do
      injector.call
      expect(Scores::Injectors::Fotmob).not_to have_received(:call)
    end
  end

  context 'when updating tours after injection' do
    let(:tour) { create(:tour, tournament_round: tournament_round) }

    before { tour }

    it 'calls PositionMalus::Updater for each tour' do
      injector.call
      expect(Scores::PositionMalus::Updater).to have_received(:call).with(tour)
    end

    it 'calls Lineups::Updater for each tour' do
      injector.call
      expect(Lineups::Updater).to have_received(:call).with(tour)
    end

    context 'with multiple tours' do
      let(:tour2) { create(:tour, tournament_round: tournament_round) }

      before { tour2 }

      it 'calls PositionMalus::Updater for all tours' do
        injector.call
        expect(Scores::PositionMalus::Updater).to have_received(:call).twice
      end

      it 'calls Lineups::Updater for all tours' do
        injector.call
        expect(Lineups::Updater).to have_received(:call).twice
      end
    end
  end

  context 'when there are no tours' do
    it 'does not call PositionMalus::Updater' do
      injector.call
      expect(Scores::PositionMalus::Updater).not_to have_received(:call)
    end

    it 'does not call Lineups::Updater' do
      injector.call
      expect(Lineups::Updater).not_to have_received(:call)
    end
  end
end

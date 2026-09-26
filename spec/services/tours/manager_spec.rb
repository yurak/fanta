RSpec.describe Tours::Manager do
  describe '#call' do
    subject(:manager) { described_class.new(tour, status) }

    let(:tour) { create(:tour) }
    let(:status) { 'status' }

    context 'with initial tour and invalid status' do
      before do
        manager.call
      end

      it { expect(tour.reload.status).to eq('inactive') }
    end

    context 'with initial tour and set_lineup status' do
      let(:status) { 'set_lineup' }

      before do
        manager.call
      end

      it { expect(tour.reload.status).to eq('set_lineup') }
    end

    context 'with set_lineup tour and invalid status' do
      let(:tour) { create(:set_lineup_tour) }

      before do
        manager.call
      end

      it { expect(tour.reload.status).to eq('set_lineup') }
    end

    context 'with set_lineup tour and locked status' do
      let(:tournament_round) { create(:tournament_round) }
      let(:tour) { create(:set_lineup_tour, tournament_round: tournament_round) }
      let(:status) { 'locked' }

      before do
        create(:tournament_match, tournament_round: tournament_round)
        create_list(:team, 4, league: tour.league)

        manager.call
      end

      it { expect(tour.reload.status).to eq('locked') }
    end

    context 'with set_lineup tour and locked status and players out of squad' do
      let(:tour) { create(:set_lineup_tour) }
      let(:status) { 'locked' }

      before { manager.call }

      it { expect(tour.reload.status).to eq('locked') }
    end

    context 'with set_lineup tour, valid status with old teams lineups' do
      let(:tour) { create(:set_lineup_tour) }
      let(:status) { 'locked' }

      before do
        old_tour = create(:closed_tour, league: tour.league)
        create(:lineup, tour: old_tour, team: create(:team, league: tour.league))

        manager.call
      end

      it { expect(tour.reload.status).to eq('locked') }
    end

    context 'with locked tour and invalid status' do
      let(:tour) { create(:locked_tour) }

      before do
        manager.call
      end

      it { expect(tour.reload.status).to eq('locked') }
    end

    context 'with locked tour and postponed status' do
      let(:tour) { create(:locked_tour) }
      let(:status) { 'postponed' }

      before do
        manager.call
      end

      it { expect(tour.reload.status).to eq('postponed') }
    end

    context 'with locked tour and closed status with not finished tournament_round' do
      let(:tour) { create(:locked_tour) }
      let(:status) { 'closed' }

      before do
        manager.call
      end

      it { expect(tour.reload.status).to eq('locked') }
    end

    context 'with locked tour and closed status with finished tournament_round' do
      let(:tournament_round) { create(:tournament_round, :with_finished_matches) }
      let(:tour) { create(:locked_tour, tournament_round: tournament_round) }
      let(:status) { 'closed' }

      before do
        manager.call
      end

      it { expect(tour.reload.status).to eq('closed') }
    end

    # A postponed round settles after the rounds that followed it, and closing it stamps today's
    # table into its own history slot — the league has to be replayed for the trend to make sense.
    context 'when a postponed tour closes after later rounds' do
      let(:league) { create(:league) }
      let(:tournament_round) { create(:tournament_round, :with_finished_matches) }
      let(:tour) { create(:postponed_tour, league: league, number: 7, tournament_round: tournament_round) }
      let(:status) { 'closed' }

      before do
        create(:closed_tour, league: league, number: 26)
        allow(Results::HistoryRebuilder).to receive(:call)
        manager.call
      end

      it { expect(tour.reload.status).to eq('closed') }

      it 'rebuilds the league history' do
        expect(Results::HistoryRebuilder).to have_received(:call).with(tour.league)
      end
    end

    context 'when a tour closes in round order' do
      let(:league) { create(:league) }
      let(:tournament_round) { create(:tournament_round, :with_finished_matches) }
      let(:tour) { create(:locked_tour, league: league, number: 27, tournament_round: tournament_round) }
      let(:status) { 'closed' }

      before do
        create(:closed_tour, league: league, number: 26)
        allow(Results::HistoryRebuilder).to receive(:call)
        manager.call
      end

      it 'leaves the history alone' do
        expect(Results::HistoryRebuilder).not_to have_received(:call)
      end
    end
  end
end

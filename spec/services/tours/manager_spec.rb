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
      let(:tournament_round) { create(:tournament_round) }
      let(:tour) { create(:set_lineup_tour, tournament_round: tournament_round) }
      let(:status) { 'locked' }
      let(:team) { create(:team, league: tour.league) }
      let!(:lineup) { create(:lineup, :with_match_players, tour: tour, team: team) }

      before do
        create(:tournament_match, tournament_round: tournament_round)
        create_list(:team, 4, league: tour.league)
        round_player = create(:round_player, tournament_round: tournament_round)
        create(:player_team, team: team, player: round_player.player)

        manager.call
      end

      it 'generates out_of_squad match_players' do
        expect(lineup.match_players.not_in_lineup.count).to eq(1)
      end
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
  end
end

RSpec.describe Leagues::Activator do
  describe '#call' do
    subject(:activator) { described_class.new(league_id) }

    let(:league) { create(:league) }
    let(:league_id) { league.id }

    context 'with blank league_id' do
      let(:league_id) { nil }

      it { expect(activator.call).to be(false) }
    end

    context 'when league is active' do
      let(:league) { create(:active_league) }
      let(:league_id) { league.id }

      it { expect(activator.call).to be(false) }
    end

    context 'when league is archived' do
      let(:league) { create(:archived_league) }

      it { expect(activator.call).to be(false) }
    end

    context 'when league is initial and without teams' do
      it { expect(activator.call).to be(false) }
    end

    context 'when league is initial, with teams and base configs' do
      let!(:league) { create(:league, :with_five_teams) }
      let(:result) do
        create(:tournament_round, number: 1, tournament: league.tournament, season: league.season)
        create(:tournament_round, number: 2, tournament: league.tournament, season: league.season)
        create(:tournament_round, number: 3, tournament: league.tournament, season: league.season)
        activator.call
      end

      before { result }

      it 'returns truthy' do
        expect(result).to be_truthy
      end

      it 'sets league status to active' do
        expect(league.reload).to be_active
      end

      it 'updates transfer_slots for all teams' do
        expect(league.teams.reload.map(&:transfer_slots).uniq).to eq([20])
      end

      it 'resets budget to DEFAULT_BUDGET for all teams' do
        expect(league.teams.reload.map(&:budget).uniq).to eq([Team::DEFAULT_BUDGET])
      end

      it 'creates auctions' do
        expect(league.auctions.count).to eq(5)
      end

      it 'creates auctions with sequential numbers' do
        expect(league.auctions.pluck(:number).sort).to eq([1, 2, 3, 4, 5])
      end

      it 'creates auctions with base_date' do
        expect(league.auctions.map(&:base_date)).to all(be_present)
      end

      it 'creates results' do
        expect(league.results.count).to eq(5)
      end

      it 'creates tours' do
        expect(league.tours.count).to eq(3)
      end
    end

    context 'when league has teams with players before activation' do
      let!(:league) { create(:league) }
      let!(:team) { create(:team, :with_5_players, league: league) }

      before do
        create(:result, team: team, league: league)
        create(:tournament_round, number: 1, tournament: league.tournament, season: league.season)
        activator.call
      end

      it 'clears players from teams' do
        expect(team.reload.players).to be_empty
      end
    end

    context 'when league is initial, with teams and only 1 auction' do
      let!(:league) { create(:league, :with_five_teams, auction_number: 1) }

      before do
        create(:tournament_round, number: 1, tournament: league.tournament, season: league.season)
        activator.call
      end

      it 'sets transfer_slots to 0 (no intermediate auctions)' do
        expect(league.teams.reload.first.transfer_slots).to eq(0)
      end

      it 'creates 1 auction' do
        expect(league.auctions.count).to eq(1)
      end
    end

    context 'when league is initial, with teams and custom configs' do
      let!(:league) { create(:league, :with_five_teams, tour_difference: 1, auction_number: 3) }

      before do
        create(:tournament_round, number: 1, tournament: league.tournament, season: league.season)
        create(:tournament_round, number: 2, tournament: league.tournament, season: league.season)
        create(:tournament_round, number: 3, tournament: league.tournament, season: league.season)
        activator.call
      end

      it 'updates transfer_slots based on auction_number' do
        expect(league.teams.reload.first.transfer_slots).to eq(10)
      end

      it 'creates auctions' do
        expect(league.auctions.count).to eq(3)
      end

      it 'creates auctions with sequential numbers' do
        expect(league.auctions.pluck(:number).sort).to eq([1, 2, 3])
      end

      it 'creates results' do
        expect(league.results.count).to eq(5)
      end

      it 'creates tours respecting tour_difference' do
        expect(league.tours.count).to eq(2)
      end
    end
  end
end

RSpec.describe Leagues::Activator do
  describe '#call' do
    subject(:activator) { described_class.new(league_id, deadline) }

    let(:league) { create(:league) }
    let(:league_id) { league.id }
    let(:deadline) { 1.week.from_now }

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

      it 'creates the first auction round' do
        expect(league.auctions.find_by(number: 1).auction_rounds.count).to eq(1)
      end

      it 'creates the first auction round with the provided deadline' do
        auction_round = league.auctions.find_by(number: 1).auction_rounds.first
        expect(auction_round.deadline).to be_within(1.second).of(deadline)
      end

      it 'sets the first auction to blind_bids' do
        expect(league.auctions.find_by(number: 1)).to be_blind_bids
      end

      it 'creates auction bids for all teams' do
        auction_round = league.auctions.find_by(number: 1).auction_rounds.first
        expect(auction_round.auction_bids.count).to eq(league.teams.count)
      end

      it 'locks player_bids for all auction bids' do
        auction_round = league.auctions.find_by(number: 1).auction_rounds.first
        expect(auction_round.auction_bids.map(&:player_bids_locked)).to all(be true)
      end
    end

    context 'when teams have existing auction bids without a round' do
      let!(:league) { create(:league, :with_five_teams) }
      let(:team_with_bid) { league.teams.first }
      let!(:existing_bid) { create(:auction_bid, team: team_with_bid, auction_round: nil) }

      before do
        create(:tournament_round, number: 1, tournament: league.tournament, season: league.season)
        activator.call
      end

      it 'links existing bid to the first auction round' do
        auction_round = league.auctions.find_by(number: 1).auction_rounds.first
        expect(existing_bid.reload.auction_round).to eq(auction_round)
      end

      it 'does not create a duplicate bid for the team with existing bid' do
        auction_round = league.auctions.find_by(number: 1).auction_rounds.first
        expect(auction_round.auction_bids.where(team: team_with_bid).count).to eq(1)
      end

      it 'creates new bids for teams without existing bids' do
        auction_round = league.auctions.find_by(number: 1).auction_rounds.first
        expect(auction_round.auction_bids.count).to eq(league.teams.count)
      end
    end

    context 'when a team has a user (notification delivery)' do
      let!(:league) { create(:league) }

      before do
        create(:team, :with_user, :with_result, league: league)
        create(:tournament_round, number: 1, tournament: league.tournament, season: league.season)
        activator.call
      end

      it 'creates auction_start_bids notification for the team' do
        auction_round = league.auctions.find_by(number: 1).auction_rounds.first
        expect(Notification.where(notifiable: auction_round, kind: :auction_start_bids).count).to eq(1)
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

RSpec.describe Team do
  subject(:team) { create(:team) }

  describe 'Associations' do
    it { is_expected.to belong_to(:league).optional }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:auction_bids).dependent(:destroy) }
    it { is_expected.to have_many(:player_teams).dependent(:destroy) }
    it { is_expected.to have_many(:players).through(:player_teams) }
    it { is_expected.to have_many(:lineups).order('tour_id desc').dependent(:destroy).inverse_of(:team) }
    it { is_expected.to have_many(:results).dependent(:destroy) }
    it { is_expected.to have_many(:transfers).dependent(:destroy) }

    it {
      expect(team).to have_many(:host_matches).class_name('Match').with_foreign_key('host_id')
                                              .dependent(:destroy).inverse_of(:host)
    }

    it {
      expect(team).to have_many(:guest_matches).class_name('Match').with_foreign_key('guest_id')
                                               .dependent(:destroy).inverse_of(:guest)
    }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(18) }
    it { is_expected.to validate_presence_of :code }
    it { is_expected.to validate_length_of(:code).is_at_least(2).is_at_most(3) }
    it { is_expected.to validate_length_of(:human_name).is_at_least(2).is_at_most(24) }
  end

  describe '#reset' do
    before do
      team.reset
    end

    context 'without players' do
      it 'updates team budget' do
        expect(team.budget).to eq(260)
      end

      it 'updates team transfer slots' do
        expect(team.transfer_slots).to eq(16)
      end
    end

    context 'with players' do
      subject(:team) { create(:team, :with_players) }

      it 'remove team players' do
        expect(team.players.count).to eq(0)
      end

      it 'updates team budget' do
        expect(team.budget).to eq(260)
      end

      it 'updates team transfer slots' do
        expect(team.transfer_slots).to eq(16)
      end
    end
  end

  describe '#league_matches' do
    context 'without matches' do
      it 'returns empty array' do
        expect(team.league_matches).to eq([])
      end
    end

    context 'without league matches' do
      let(:team) { create(:team, :with_matches) }

      it 'returns empty array' do
        expect(team.league_matches).to eq([])
      end
    end

    context 'with league matches' do
      let(:matches) { create_list(:match, 3, host: team, tour: create(:tour, league: team.league)) }

      it 'returns array with matches' do
        expect(team.league_matches).to eq(matches)
      end
    end
  end

  describe '#league_transfers' do
    context 'without transfers' do
      it 'returns empty array' do
        expect(team.league_transfers).to eq([])
      end
    end

    context 'without league transfers' do
      let(:transfer) { create(:transfer, team: team) }

      it 'returns empty array' do
        expect(team.league_transfers).to eq([])
      end
    end

    context 'with league transfers' do
      let(:transfers) { create_list(:transfer, 3, team: team, league: team.league) }

      it 'returns array with matches' do
        expect(team.league_transfers).to eq(transfers)
      end
    end
  end

  describe '#logo_path' do
    context 'when logo does not exist' do
      it 'returns default path' do
        expect(team.logo_path).to eq(ActionController::Base.helpers.asset_path('default_logo.png'))
      end
    end

    context 'when logo url exists' do
      let(:team) { create(:team, logo_url: logo_url) }
      let(:logo_url) { 'url/logo.png' }

      it 'returns path to team logo' do
        expect(team.logo_path).to eq(logo_url)
      end
    end
  end

  describe '#next_round' do
    context 'when league without tours' do
      it 'returns nil' do
        expect(team.next_round).to be_nil
      end
    end

    context 'when league with initial tours' do
      it 'returns first initial tour' do
        tours = create_list(:tour, 3, league: team.league)

        expect(team.next_round).to eq(tours.first)
      end
    end

    context 'when league with initial tours and one set_lineup' do
      it 'returns first active tour' do
        create_list(:tour, 3, league: team.league)
        tour = create(:tour, league: team.league, status: :set_lineup)

        expect(team.next_round).to eq(tour)
      end
    end
  end

  describe '#opponent_by_match(match)' do
    context 'when team is host' do
      it 'returns guest team' do
        match = create(:match, host: team, tour: create(:tour, league: team.league))

        expect(team.opponent_by_match(match)).to eq(match.guest)
      end
    end

    context 'when team is guest' do
      it 'returns host team' do
        match = create(:match, guest: team, tour: create(:tour, league: team.league))

        expect(team.opponent_by_match(match)).to eq(match.host)
      end
    end
  end

  describe '#next_opponent' do
    context 'when league without tours and matches' do
      it 'returns nil' do
        expect(team.next_opponent).to be_nil
      end
    end

    context 'when league with tours and without matches' do
      it 'returns nil' do
        create_list(:tour, 3, league: team.league)

        expect(team.next_opponent).to be_nil
      end
    end

    context 'when league with tours and matches and team is host' do
      it 'returns first match guest' do
        matches = create_list(:match, 3, host: team, tour: create(:tour, league: team.league))

        expect(team.next_opponent).to eq(matches.first.guest)
      end
    end

    context 'when league with tours and matches and team is guest' do
      it 'returns first match host' do
        matches = create_list(:match, 3, guest: team, tour: create(:tour, league: team.league))

        expect(team.next_opponent).to eq(matches.first.host)
      end
    end
  end

  describe '#players_not_in(lineup)' do
    context 'without lineup' do
      it 'returns nil' do
        expect(team.players_not_in(nil)).to be_nil
      end
    end

    context 'with lineup' do
      let(:team) { create(:team, :with_lineup) }
      let(:lineup) { team.lineups.last }

      it 'returns players' do
        expect(team.players_not_in(lineup).count).to eq(7)
      end
    end
  end

  describe '#best_lineup' do
    context 'without lineup' do
      it 'returns nil' do
        expect(team.best_lineup).to be_nil
      end
    end

    context 'with lineup' do
      it 'returns lineup with best total score' do
        create(:lineup, :with_team_and_score_six, team: team, tour: create(:closed_tour, league: team.league))
        lineup_two = create(:lineup, :with_team_and_score_seven, team: team, tour: create(:closed_tour, league: team.league))
        create(:lineup, :with_team_and_score_five, team: team, tour: create(:closed_tour, league: team.league))

        expect(team.best_lineup).to eq(lineup_two)
      end
    end
  end

  describe '#vacancies' do
    context 'without players' do
      it 'returns max value' do
        expect(team.vacancies).to eq(Team::MAX_PLAYERS)
      end
    end

    context 'with players' do
      let(:team) { create(:team, :with_15_players) }

      it 'returns number of empty vacancies' do
        expect(team.vacancies).to eq(11)
      end
    end

    context 'with max number of players' do
      let(:team) { create(:team, :with_players) }

      it 'returns zero' do
        expect(team.vacancies).to eq(0)
      end
    end
  end

  describe '#full_squad?' do
    context 'without players' do
      it 'returns false' do
        expect(team.full_squad?).to be(false)
      end
    end

    context 'with players' do
      let(:team) { create(:team, :with_15_players) }

      it 'returns false' do
        expect(team.full_squad?).to be(false)
      end
    end

    context 'with max number of players' do
      let(:team) { create(:team, :with_players) }

      it 'returns true' do
        expect(team.full_squad?).to be(true)
      end
    end
  end

  describe '#vacancies?' do
    context 'without players' do
      it 'returns true' do
        expect(team.vacancies?).to be(true)
      end
    end

    context 'with players' do
      let(:team) { create(:team, :with_15_players) }

      it 'returns true' do
        expect(team.vacancies?).to be(true)
      end
    end

    context 'with max number of players' do
      let(:team) { create(:team, :with_players) }

      it 'returns false' do
        expect(team.vacancies?).to be(false)
      end
    end
  end

  describe '#max_rate' do
    context 'with full budget' do
      it 'returns max_rate value' do
        expect(team.max_rate).to eq(235)
      end
    end

    context 'with few players' do
      let(:team) { create(:team, :with_15_players, budget: 99) }

      it 'returns max_rate value' do
        expect(team.max_rate).to eq(89)
      end
    end

    context 'with max number of players and positive budget' do
      let(:team) { create(:team, :with_players, budget: 13) }

      it 'returns zero' do
        expect(team.max_rate).to eq(0)
      end
    end
  end

  describe '#sales_period?' do
    context 'without auctions' do
      it 'returns false' do
        expect(team.sales_period?).to be(false)
      end
    end

    context 'without sales auctions' do
      before do
        create(:auction, league: team.league)
      end

      it 'returns false' do
        expect(team.sales_period?).to be(false)
      end
    end

    context 'with sales auctions' do
      before do
        create(:auction, status: 'sales', league: team.league)
      end

      it 'returns true' do
        expect(team.sales_period?).to be(true)
      end
    end
  end

  describe '#available_transfers' do
    context 'without transfer slots' do
      it 'returns zero' do
        expect(team.available_transfers).to eq(0)
      end
    end

    context 'without auction' do
      let(:team) { create(:team, transfer_slots: Team::TRANSFER_SLOTS) }

      it 'returns zero' do
        expect(team.available_transfers).to eq(0)
      end
    end

    context 'without sales auctions' do
      let(:team) { create(:team, transfer_slots: Team::TRANSFER_SLOTS) }

      before do
        create(:auction, league: team.league)
      end

      it 'returns zero' do
        expect(team.available_transfers).to eq(0)
      end
    end

    context 'with sales auctions with number 1' do
      let(:team) { create(:team, transfer_slots: Team::TRANSFER_SLOTS) }

      before do
        create(:auction, status: 'sales', league: team.league, number: 1)
      end

      it 'returns number of available slots' do
        expect(team.available_transfers).to eq(8)
      end
    end

    context 'with sales auctions with number 2' do
      let(:team) { create(:team, transfer_slots: Team::TRANSFER_SLOTS) }

      before do
        create(:auction, status: 'sales', league: team.league, number: 2)
      end

      it 'returns number of available slots' do
        expect(team.available_transfers).to eq(10)
      end
    end

    context 'with sales auctions with number 5' do
      let(:team) { create(:team, transfer_slots: Team::TRANSFER_SLOTS) }

      before do
        create(:auction, status: 'sales', league: team.league, number: 5)
      end

      it 'returns number of available slots' do
        expect(team.available_transfers).to eq(16)
      end
    end
  end

  describe '#prepared_sales_count' do
    context 'without auctions' do
      it 'returns 0' do
        expect(team.prepared_sales_count).to eq(0)
      end
    end

    context 'without initial or sales auctions' do
      before do
        create(:auction, status: 'blind_bids', league: team.league)
      end

      it 'returns 0' do
        expect(team.prepared_sales_count).to eq(0)
      end
    end

    context 'with initial auction and without transferable players and outgoing transfers' do
      before do
        create(:auction, league: team.league)
      end

      it 'returns 0' do
        expect(team.prepared_sales_count).to eq(0)
      end
    end

    context 'with initial auction and transferable players and without outgoing transfers' do
      let!(:player_teams) { create_list(:player_team, 2, team: team, transfer_status: 'transferable') }

      before do
        create(:auction, league: team.league)
      end

      it 'returns prepared sales count' do
        expect(team.prepared_sales_count).to eq(player_teams.count)
      end
    end

    context 'with sales auction and outgoing transfers and without transferable players' do
      let(:auction) { create(:auction, status: 'sales', league: team.league) }
      let!(:transfers) { create_list(:transfer, 2, team: team, league: team.league, auction: auction, status: 'outgoing') }

      it 'returns prepared sales count' do
        expect(team.prepared_sales_count).to eq(transfers.count)
      end
    end

    context 'with sales auction, outgoing transfers and transferable players' do
      let!(:player_teams) { create_list(:player_team, 2, team: team, transfer_status: 'transferable') }
      let(:auction) { create(:auction, status: 'sales', league: team.league) }
      let!(:transfers) { create_list(:transfer, 2, team: team, league: team.league, auction: auction, status: 'outgoing') }

      it 'returns prepared sales count' do
        expect(team.prepared_sales_count).to eq(transfers.count + player_teams.count)
      end
    end
  end

  describe '#spent_budget(auction)' do
    context 'without auctions' do
      it 'returns 0' do
        expect(team.spent_budget(nil)).to eq(0)
      end
    end

    context 'with auction and without incoming transfers' do
      let(:auction) { create(:auction, league: team.league) }

      it 'returns 0' do
        expect(team.spent_budget(auction)).to eq(0)
      end
    end

    context 'with auction and with incoming transfer on other auction' do
      let(:auction) { create(:auction, league: team.league) }

      before do
        create(:transfer, league: team.league, team: team, price: 77)
      end

      it 'returns 0' do
        expect(team.spent_budget(auction)).to eq(0)
      end
    end

    context 'with auction and incoming transfer' do
      let(:auction) { create(:auction, league: team.league) }
      let!(:transfer) { create(:transfer, auction: auction, league: team.league, team: team, price: 77) }

      it 'returns spent budget value' do
        expect(team.spent_budget(auction)).to eq(transfer.price)
      end
    end
  end

  describe '#dumped_player_ids(auction)' do
    context 'without auction' do
      it 'returns empty array' do
        expect(team.dumped_player_ids(nil)).to eq([])
      end
    end

    context 'with auction and without outgoing transfers' do
      let(:auction) { create(:auction, league: team.league) }

      it 'returns empty array' do
        expect(team.dumped_player_ids(auction)).to eq([])
      end
    end

    context 'with auction and with outgoing transfer on other auction' do
      let(:auction) { create(:auction, league: team.league) }

      before do
        create(:transfer, status: 'outgoing', league: team.league, team: team, price: 77)
      end

      it 'returns empty array' do
        expect(team.dumped_player_ids(auction)).to eq([])
      end
    end

    context 'with auction and outgoing transfer' do
      let(:auction) { create(:auction, league: team.league) }
      let!(:transfer) { create(:transfer, status: 'outgoing', auction: auction, league: team.league, team: team, price: 77) }

      it 'returns spent budget value' do
        expect(team.dumped_player_ids(auction)).to eq([transfer.player_id])
      end
    end
  end

  describe '#avg_ts' do
    context 'without lineups' do
      it 'returns zero' do
        expect(team.avg_ts).to eq(0)
      end
    end

    context 'with lineups' do
      before do
        create_list(:lineup, 2, team: team, tour: create(:tour, league: team.league))
      end

      context 'without result' do
        it 'returns zero' do
          expect(team.avg_ts).to eq(0)
        end
      end

      context 'with result' do
        before do
          create(:result, team: team, league: team.league, total_score: 143)
        end

        it 'returns zero' do
          expect(team.avg_ts).to eq(71.5)
        end
      end
    end
  end

  describe '#avg_points' do
    context 'without lineups' do
      it 'returns zero' do
        expect(team.avg_points).to eq(0)
      end
    end

    context 'with lineups' do
      before do
        create_list(:lineup, 2, team: team, tour: create(:tour, league: team.league))
      end

      context 'without result' do
        it 'returns zero' do
          expect(team.avg_points).to eq(0)
        end
      end

      context 'with result' do
        before do
          create(:result, team: team, league: team.league, points: 55)
        end

        it 'returns zero' do
          expect(team.avg_points).to eq(27.5)
        end
      end
    end
  end

  describe '#league_lineups_number' do
    context 'without lineups' do
      it 'returns zero' do
        expect(team.league_lineups_number).to eq(0)
      end
    end

    context 'with lineups' do
      before do
        create_list(:lineup, 2, team: team, tour: create(:tour, league: team.league))
      end

      it 'returns number of lineups' do
        expect(team.league_lineups_number).to eq(2)
      end
    end
  end

  describe '#league_lineups' do
    context 'without lineups' do
      it 'returns empty array' do
        expect(team.league_lineups).to eq([])
      end
    end

    context 'with lineups' do
      before do
        create_list(:lineup, 2, team: team, tour: create(:tour, league: team.league))
      end

      it 'returns array with lineups' do
        expect(team.league_lineups.count).to eq(2)
      end
    end
  end

  describe '#league_result' do
    context 'without results' do
      it 'returns nil' do
        expect(team.league_result).to be_nil
      end
    end

    context 'with lineup from other league' do
      before do
        create(:result, team: team)
      end

      it 'returns nil' do
        expect(team.league_result).to be_nil
      end
    end

    context 'with result from current league' do
      let!(:result) { create(:result, team: team, league: team.league) }

      it 'returns array with lineups' do
        expect(team.league_result).to eq(result)
      end
    end
  end
end

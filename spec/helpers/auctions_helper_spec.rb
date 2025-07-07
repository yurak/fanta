RSpec.describe AuctionsHelper do
  let(:auction) { create(:auction) }

  describe '#auction_link(auction)' do
    context 'with initial auction' do
      it 'returns path' do
        expect(helper.auction_link(auction)).to eq(league_auction_path(auction.league, auction))
      end
    end

    context 'with sales auction' do
      let(:auction) { create(:auction, status: :sales) }

      it 'returns path' do
        expect(helper.auction_link(auction)).to eq(league_auction_path(auction.league, auction))
      end
    end

    context 'with blind_bids auction without auction rounds' do
      let(:auction) { create(:auction, status: :blind_bids) }

      it 'returns # path' do
        expect(helper.auction_link(auction)).to eq(league_auction_transfers_path(auction.league, auction))
      end
    end

    context 'with blind_bids auction with active auction rounds' do
      let(:auction) { create(:auction, status: :blind_bids) }
      let!(:auction_round) { create(:auction_round, auction: auction) }

      it 'returns # path' do
        expect(helper.auction_link(auction)).to eq(auction_round_path(auction_round))
      end
    end

    context 'with blind_bids auction with closed auction rounds' do
      let(:auction) { create(:auction, status: :blind_bids) }

      before do
        create(:closed_auction_round, auction: auction)
      end

      it 'returns # path' do
        expect(helper.auction_link(auction)).to eq(league_auction_transfers_path(auction.league, auction))
      end
    end

    context 'with live auction' do
      let(:auction) { create(:auction, status: :live) }

      it 'returns path' do
        expect(helper.auction_link(auction)).to eq(league_auction_transfers_path(auction.league, auction))
      end
    end

    context 'with closed auction' do
      let(:auction) { create(:auction, status: :closed) }

      it 'returns path' do
        expect(helper.auction_link(auction)).to eq(league_auction_path(auction.league, auction))
      end
    end
  end

  describe '#dropping_link(auction)' do
    context 'with initial auction' do
      it 'returns path' do
        expect(helper.dropping_link(auction)).to eq(league_auction_path(auction.league, auction))
      end
    end

    context 'with sales auction without current_user' do
      let(:auction) { create(:auction, status: :sales) }

      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'returns path' do
        expect(helper.dropping_link(auction)).to eq(league_auction_path(auction.league, auction))
      end
    end

    context 'with sales auction and logged user' do
      let(:auction) { create(:auction, status: :sales) }
      let(:user) { create(:user) }
      let!(:team) { create(:team, league: auction.league, user: user) }
      let!(:player_team) { create(:player_team, team: team) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns path' do
        expect(helper.dropping_link(auction)).to eq(edit_team_player_team_path(team, player_team))
      end
    end

    context 'with blind_bids auction' do
      let(:auction) { create(:auction, status: :blind_bids) }

      it 'returns # path' do
        expect(helper.dropping_link(auction)).to eq(league_auction_transfers_path(auction.league, auction, type: 'out'))
      end
    end

    context 'with live auction' do
      let(:auction) { create(:auction, status: :live) }

      it 'returns path' do
        expect(helper.dropping_link(auction)).to eq(league_auction_path(auction.league, auction))
      end
    end

    context 'with closed auction' do
      let(:auction) { create(:auction, status: :closed) }

      it 'returns path' do
        expect(helper.dropping_link(auction)).to eq(league_auction_transfers_path(auction.league, auction, type: 'out'))
      end
    end
  end

  describe '#auction_status(auction)' do
    context 'with initial auction without deadline' do
      it 'returns status' do
        expect(helper.auction_status(auction)).to eq('to_be_decided')
      end
    end

    context 'with initial auction with deadline' do
      let(:auction) { create(:auction, deadline: FFaker::Time.date) }

      it 'returns status' do
        expect(helper.auction_status(auction)).to eq('coming_soon')
      end
    end

    context 'with sales auction' do
      let(:auction) { create(:auction, status: :sales) }

      it 'returns status' do
        expect(helper.auction_status(auction)).to eq('coming_soon')
      end
    end

    context 'with blind_bids auction' do
      let(:auction) { create(:auction, status: :blind_bids) }

      it 'returns status' do
        expect(helper.auction_status(auction)).to eq('ongoing')
      end
    end

    context 'with live auction' do
      let(:auction) { create(:auction, status: :live) }

      it 'returns status' do
        expect(helper.auction_status(auction)).to eq('ongoing')
      end
    end

    context 'with closed auction' do
      let(:auction) { create(:auction, status: :closed) }

      it 'returns status' do
        expect(helper.auction_status(auction)).to eq('completed')
      end
    end
  end

  describe '#auction_dates(auction)' do
    context 'with initial auction without deadline and base date' do
      it 'returns nil' do
        expect(helper.auction_dates(auction)).to be_nil
      end
    end

    context 'with initial auction without deadline and with base date' do
      let(:auction) { create(:auction, base_date: 'August 2025') }

      it 'returns base date' do
        expect(helper.auction_dates(auction)).to eq(auction.base_date)
      end
    end

    context 'with initial auction with deadline' do
      let(:auction) { create(:auction, deadline: FFaker::Time.date) }

      it 'returns string with deadline' do
        expect(helper.auction_dates(auction)).to eq("Started on #{auction.deadline.strftime('%b %e, %Y')}")
      end
    end

    context 'with sales auction without deadline and base date' do
      let(:auction) { create(:auction, status: :sales) }

      it 'returns nil' do
        expect(helper.auction_dates(auction)).to be_nil
      end
    end

    context 'with sales auction without deadline and with base date' do
      let(:auction) { create(:auction, status: :sales, base_date: 'August 2025') }

      it 'returns base date' do
        expect(helper.auction_dates(auction)).to eq(auction.base_date)
      end
    end

    context 'with sales auction with deadline' do
      let(:auction) { create(:auction, status: :sales, deadline: FFaker::Time.date) }

      it 'returns string with deadline' do
        expect(helper.auction_dates(auction)).to eq("Started on #{auction.deadline.strftime('%b %e, %Y')}")
      end
    end

    context 'with blind_bids auction without deadline' do
      let(:auction) { create(:auction, status: :blind_bids) }

      it 'returns nil' do
        expect(helper.auction_dates(auction)).to be_nil
      end
    end

    context 'with blind_bids auction with deadline' do
      let(:auction) { create(:auction, status: :blind_bids, deadline: FFaker::Time.date) }

      it 'returns string with deadline' do
        expect(helper.auction_dates(auction)).to eq(auction.deadline.strftime('%a, %b %e, %H:%M').to_s)
      end
    end

    context 'with live auction' do
      let(:auction) { create(:auction, status: :live) }

      it 'returns string' do
        expect(helper.auction_dates(auction)).to eq('--:--')
      end
    end

    context 'with closed auction' do
      let(:auction) { create(:auction, status: :closed) }

      it 'returns string with round dates' do
        expect(helper.auction_dates(auction)).to eq(' - ')
      end
    end
  end

  describe '#auction_dropping_status(auction)' do
    context 'with initial auction' do
      it 'returns status' do
        expect(helper.auction_dropping_status(auction)).to eq('coming_soon')
      end
    end

    context 'with sales auction' do
      let(:auction) { create(:auction, status: :sales) }

      it 'returns status' do
        expect(helper.auction_dropping_status(auction)).to eq('ongoing')
      end
    end

    context 'with blind_bids auction' do
      let(:auction) { create(:auction, status: :blind_bids) }

      it 'returns status' do
        expect(helper.auction_dropping_status(auction)).to eq('completed')
      end
    end

    context 'with live auction' do
      let(:auction) { create(:auction, status: :live) }

      it 'returns status' do
        expect(helper.auction_dropping_status(auction)).to eq('completed')
      end
    end

    context 'with closed auction' do
      let(:auction) { create(:auction, status: :closed) }

      it 'returns status' do
        expect(helper.auction_dropping_status(auction)).to eq('completed')
      end
    end
  end

  describe '#user_auction_bid(auction_round, league)' do
    context 'without current_user' do
      let(:auction) { create(:auction) }
      let(:auction_round) { create(:auction_round, auction: auction) }

      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'returns nil' do
        expect(helper.user_auction_bid(auction_round, auction.league)).to be_nil
      end
    end

    context 'with logged user and without auction_bid' do
      let(:auction) { create(:auction) }
      let(:auction_round) { create(:auction_round, auction: auction) }
      let(:user) { create(:user) }

      before do
        create(:team, league: auction.league, user: user)
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns nil' do
        expect(helper.user_auction_bid(auction_round, auction.league)).to be_nil
      end
    end

    context 'with logged user and auction_bid' do
      let(:auction) { create(:auction) }
      let(:auction_round) { create(:auction_round, auction: auction) }
      let(:user) { create(:user) }
      let(:team) { create(:team, league: auction.league, user: user) }
      let!(:auction_bid) { create(:auction_bid, team: team, auction_round: auction_round) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns auction_bid' do
        expect(helper.user_auction_bid(auction_round, auction.league)).to eq(auction_bid)
      end
    end
  end

  describe '#next_bid_status(auction_bid)' do
    let(:auction_bid) { create(:auction_bid) }

    context 'without auction_bid' do
      let(:auction_bid) { nil }

      it 'returns empty string' do
        expect(helper.next_bid_status(auction_bid)).to eq('')
      end
    end

    context 'with initial auction_bid' do
      it 'returns submitted as next status' do
        expect(helper.next_bid_status(auction_bid)).to eq('submitted')
      end
    end

    context 'with ongoing auction_bid' do
      let(:auction_bid) { create(:auction_bid, status: 'ongoing') }

      it 'returns submitted as next status' do
        expect(helper.next_bid_status(auction_bid)).to eq('submitted')
      end
    end

    context 'with submitted auction_bid' do
      let(:auction_bid) { create(:auction_bid, status: 'submitted') }

      it 'returns completed as next status' do
        expect(helper.next_bid_status(auction_bid)).to eq('completed')
      end
    end

    context 'with completed auction_bid' do
      let(:auction_bid) { create(:auction_bid, status: 'completed') }

      it 'returns ongoing as next status' do
        expect(helper.next_bid_status(auction_bid)).to eq('ongoing')
      end
    end
  end

  describe '#max_bid(league)' do
    let(:league) { create(:league) }

    context 'without current_user' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'returns nil' do
        expect(helper.max_bid(league)).to be_nil
      end
    end

    context 'with logged user and without team in league' do
      let(:user) { create(:user) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns nil' do
        expect(helper.max_bid(league)).to be_nil
      end
    end

    context 'with logged user and with team in league' do
      let(:user) { create(:user) }

      before do
        create(:team, league: league, user: user)
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns nil' do
        expect(helper.max_bid(league)).to eq(235)
      end
    end
  end

  describe '#min_bid(auction_round, player)' do
    let(:player) { create(:player) }
    let(:auction_round) { create(:auction_round) }

    before do
      allow(player).to receive(:stats_price).and_return(15)
    end

    context 'without player' do
      let(:player) { nil }

      it 'returns 1' do
        expect(helper.min_bid(auction_round, player)).to eq(1)
      end
    end

    context 'without auction_round' do
      let(:auction_round) { nil }

      it 'returns 1' do
        expect(helper.min_bid(auction_round, player)).to eq(1)
      end
    end

    context 'with not basic auction_round' do
      it 'returns 1' do
        expect(helper.min_bid(auction_round, player)).to eq(1)
      end
    end

    context 'with player stats' do
      let(:auction_round) { create(:auction_round, basic: true) }

      it 'returns player price' do
        expect(helper.min_bid(auction_round, player)).to eq(15)
      end
    end
  end
end

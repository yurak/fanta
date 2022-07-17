RSpec.describe AuctionsHelper, type: :helper do
  let(:auction) { create(:auction) }

  describe '#auction_link(auction)' do
    context 'with initial auction' do
      it 'returns path' do
        expect(helper.auction_link(auction)).to eq('#')
      end
    end

    context 'with sales auction without current_user' do
      let(:auction) { create(:auction, status: :sales) }

      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'returns path' do
        expect(helper.auction_link(auction)).to eq('#')
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
        expect(helper.auction_link(auction)).to eq(edit_team_player_team_path(team, player_team))
      end
    end

    context 'with blind_bids auction without auction rounds' do
      let(:auction) { create(:auction, status: :blind_bids) }

      it 'returns # path' do
        expect(helper.auction_link(auction)).to eq('#')
      end
    end

    context 'with blind_bids auction with auction rounds' do
      let(:auction) { create(:auction, status: :blind_bids) }
      let!(:auction_round) { create(:auction_round, auction: auction) }

      it 'returns # path' do
        expect(helper.auction_link(auction)).to eq(auction_round_path(auction_round))
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
        expect(helper.auction_link(auction)).to eq(league_auction_transfers_path(auction.league, auction))
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
end

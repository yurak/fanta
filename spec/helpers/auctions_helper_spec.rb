RSpec.describe AuctionsHelper, type: :helper do
  describe '#auction_link(auction)' do
    let(:auction) { create(:auction) }

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

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns path' do
        expect(helper.auction_link(auction)).to eq(edit_team_path(team))
      end
    end

    context 'with blind_bids auction' do
      let(:auction) { create(:auction, status: :blind_bids) }

      it 'returns path' do
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
        expect(helper.auction_link(auction)).to eq(league_auction_transfers_path(auction.league, auction))
      end
    end
  end
end

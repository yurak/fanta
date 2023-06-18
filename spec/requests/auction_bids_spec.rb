RSpec.describe 'AuctionBids' do
  describe 'PUT/PATCH #update' do
    let(:auction_bid) { create(:auction_bid) }
    let(:player_bids_attributes) { nil }

    let(:params) do
      {
        auction_bid: {
          player_bids_attributes: player_bids_attributes
        }
      }
    end

    before do
      put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      login_user
      before do
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_bid.auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when auction bid of other team' do
      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: auction_bid.auction_round.league)
        sign_in logged_user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_bid.auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction round is processing' do
      let(:auction_round) { create(:processing_auction_round) }
      let(:logged_user) { create(:user) }
      let(:auction_bid) do
        create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league), auction_round: auction_round)
      end

      before do
        sign_in logged_user
        put auction_round_auction_bid_path(auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction round is closed' do
      let(:auction_round) { create(:closed_auction_round) }
      let(:logged_user) { create(:user) }
      let(:auction_bid) do
        create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league), auction_round: auction_round)
      end

      before do
        sign_in logged_user
        put auction_round_auction_bid_path(auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when AuctionBids::Manager returns false' do
      let(:logged_user) { create(:user) }

      before do
        manager = instance_double(AuctionBids::Manager)
        allow(AuctionBids::Manager).to receive(:new).and_return(manager)
        allow(manager).to receive(:call).and_return(false)

        sign_in logged_user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_bid.auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when AuctionBids::Manager returns true' do
      let(:logged_user) { create(:user) }
      let(:auction_bid_params) { params[:auction_bid] }
      let(:params) do
        {
          auction_bid: {
            status: 'ongoing',
            player_bids_attributes: {
              '0': { player_id: '111', price: '128', id: auction_bid.player_bids[0] },
              '1': { player_id: '123', price: '9', id: auction_bid.player_bids[1] },
              '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
              '3': { player_id: '333', price: '15', id: auction_bid.player_bids[3] },
              '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] }
            }
          }
        }
      end

      before do
        manager = instance_double(AuctionBids::Manager)
        allow(AuctionBids::Manager).to receive(:new).with(auction_bid, auction_bid_params).and_return(manager)
        allow(manager).to receive(:call).and_return(true)

        sign_in logged_user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_bid.auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end
  end
end

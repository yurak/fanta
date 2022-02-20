RSpec.describe 'AuctionBids', type: :request do
  let(:auction_bid) { create(:auction_bid) }
  let(:auction_round) { auction_bid.auction_round }

  describe 'GET #new' do
    let(:team) { create(:team, :with_user) }

    before do
      get new_auction_round_auction_bid_path(auction_round)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    # TODO: add cases
  end

  describe 'POST #create' do
    let(:player_bids_attributes) do
      'TODO'
    end

    let(:params) do
      {
        auction_bid: {
          player_bids_attributes: player_bids_attributes
        }
      }
    end

    before do
      post auction_round_auction_bids_path(auction_round, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    # TODO: add cases
  end

  describe 'GET #edit' do
    before do
      get edit_auction_round_auction_bid_path(auction_round, auction_bid)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    # TODO: add cases
  end

  describe 'PUT/PATCH #update' do
    let(:player_bids_attributes) do
      'TODO'
    end

    let(:params) do
      {
        auction_bid: {
          player_bids_attributes: player_bids_attributes
        }
      }
    end

    before do
      put auction_round_auction_bid_path(auction_round, auction_bid, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    # TODO: add cases
  end
end

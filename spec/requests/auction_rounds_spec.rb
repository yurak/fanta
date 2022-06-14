RSpec.describe 'AuctionRounds', type: :request do
  let(:auction_round) { create(:auction_round) }

  describe 'GET #show' do
    before do
      get auction_round_path(auction_round)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:transfers)).not_to be_nil }
  end
end

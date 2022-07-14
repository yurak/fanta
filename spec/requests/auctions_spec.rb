RSpec.describe 'Auctions', type: :request do
  let(:league) { create(:league) }
  let(:auction) { create(:auction, league: league) }

  describe 'GET #index' do
    before do
      get league_auctions_path(league)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:auctions)).not_to be_nil }
  end

  describe 'GET #show' do
    before do
      get league_auction_path(league, auction)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get league_auction_path(league, auction)
      end

      it { expect(response).to redirect_to(league_auction_transfers_path(league, auction)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get league_auction_path(league, auction)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get league_auction_path(league, auction)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when admin is logged in and player at params' do
      let(:player) { create(:player) }
      let(:params) do
        {
          player: player.id
        }
      end

      login_admin
      before do
        get league_auction_path(league, auction, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:player)).not_to be_nil }
    end

    context 'when admin is logged in and search at params' do
      let(:player) { create(:player) }
      let(:params) do
        {
          search: player.name[0..3]
        }
      end

      login_admin
      before do
        get league_auction_path(league, auction, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:status) { 'sales' }
    let(:params) { { status: status } }

    before do
      put league_auction_path(league, auction, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        put league_auction_path(league, auction, params)
      end

      it { expect(response).to redirect_to(league_auctions_path(league)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update auction with specified status' do
        expect(auction.reload.status).not_to eq(status)
      end
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        put league_auction_path(league, auction, params)
      end

      it { expect(response).to redirect_to(league_auctions_path(league)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update auction with specified status' do
        expect(auction.reload.status).not_to eq(status)
      end
    end

    context 'with valid auction status when admin is logged in' do
      login_admin
      before do
        put league_auction_path(league, auction, params)
      end

      it { expect(response).to redirect_to(league_auctions_path(league)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates auction with specified status' do
        expect(auction.reload.status).to eq(status)
      end

      it 'calls Auctions::Manager service' do
        manager = instance_double(Auctions::Manager)
        allow(Auctions::Manager).to receive(:new).and_return(manager)
        allow(manager).to receive(:call).and_return(auction)

        put league_auction_path(league, auction, params)
      end
    end

    context 'with not valid auction status when admin is logged in' do
      let(:status) { 'closed' }

      login_admin
      before do
        put league_auction_path(league, auction, params)
      end

      it { expect(response).to redirect_to(league_auctions_path(league)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update auction with specified status' do
        expect(auction.reload.status).not_to eq(status)
      end

      it 'calls Auctions::Manager service' do
        manager = instance_double(Auctions::Manager)
        allow(Auctions::Manager).to receive(:new).and_return(manager)
        allow(manager).to receive(:call).and_return(auction)

        put league_auction_path(league, auction, params)
      end
    end
  end
end

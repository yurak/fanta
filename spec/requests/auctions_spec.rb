RSpec.describe 'Auctions' do
  let(:league) { create(:league) }
  let(:auction) { create(:auction, league: league) }

  describe 'GET #index' do
    context 'when user is logged out' do
      before do
        get league_auctions_path(league)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get league_auctions_path(league)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:auctions)).not_to be_nil }
    end
  end

  describe 'GET #show' do
    before do
      get league_auction_path(league, auction)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in and auction is not closed' do
      login_user
      before do
        get league_auction_path(league, auction)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:player_bid_groups)).to be_nil }
    end

    context 'when user is logged in and auction is closed' do
      let(:auction) { create(:auction, status: :closed, league: league) }

      login_user
      before do
        get league_auction_path(league, auction)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:player_bid_groups)).not_to be_nil }
    end

    context 'when admin is logged in and auction is closed' do
      let(:auction) { create(:auction, status: :closed, league: league) }

      login_admin
      before do
        get league_auction_path(league, auction)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:player_bid_groups)).not_to be_nil }
    end

    context 'when closed auction has no player bids (live auction type)' do
      let(:auction) { create(:auction, status: :closed, league: league) }
      let(:player) { create(:player) }
      let(:team) { create(:team, league: league) }

      login_user

      before do
        create(:transfer, auction: auction, league: league, player: player, team: team, status: :incoming)
        get league_auction_path(league, auction)
      end

      it { expect(response).to be_successful }

      it 'populates player_bid_groups with transfers as round 1' do
        groups = assigns(:player_bid_groups)
        expect(groups).to eq({ 1 => [Transfer.last] })
      end

      it 'sets active_bid to the first transfer' do
        expect(assigns(:active_bid)).to eq(Transfer.last)
      end

      it 'sets is_transfer_auction flag' do
        expect(assigns(:is_transfer_auction)).to be(true)
      end

      it 'sets active_bid_logs to empty hash' do
        expect(assigns(:active_bid_logs)).to eq({})
      end
    end

    context 'when closed live auction is filtered by player name' do
      let(:auction) { create(:auction, status: :closed, league: league) }
      let(:player) { create(:player, name: 'Messi') }
      let(:other_player) { create(:player, name: 'Ronaldo') }
      let(:team) { create(:team, league: league) }

      login_user

      before do
        create(:transfer, auction: auction, league: league, player: player, team: team, status: :incoming)
        create(:transfer, auction: auction, league: league, player: other_player, team: team, status: :incoming)
        get league_auction_path(league, auction, search: 'mess')
      end

      it 'returns only matching transfers' do
        groups = assigns(:player_bid_groups)
        expect(groups[1].map(&:player)).to eq([player])
      end
    end

    context 'when closed live auction is filtered by position' do
      let(:auction) { create(:auction, status: :closed, league: league) }
      let(:gk_player) { create(:player, :with_pos_por) }
      let(:fw_player) { create(:player) }
      let(:team) { create(:team, league: league) }
      let(:gk_position) { Position.find_by(name: Position::GOALKEEPER) }

      login_user

      before do
        create(:transfer, auction: auction, league: league, player: gk_player, team: team, status: :incoming)
        create(:transfer, auction: auction, league: league, player: fw_player, team: team, status: :incoming)
        get league_auction_path(league, auction, position: gk_position.human_name)
      end

      it 'returns only transfers matching the position' do
        groups = assigns(:player_bid_groups)
        expect(groups[1].map(&:player)).to eq([gk_player])
      end
    end

    context 'when closed live auction is filtered by team' do
      let(:auction) { create(:auction, status: :closed, league: league) }
      let(:player) { create(:player) }
      let(:other_player) { create(:player) }
      let(:team) { create(:team, league: league) }
      let(:other_team) { create(:team, league: league) }

      login_user

      before do
        create(:transfer, auction: auction, league: league, player: player, team: team, status: :incoming)
        create(:transfer, auction: auction, league: league, player: other_player, team: other_team, status: :incoming)
        get league_auction_path(league, auction, team_id: team.id)
      end

      it 'returns only transfers for the given team' do
        groups = assigns(:player_bid_groups)
        expect(groups[1].map(&:player)).to eq([player])
      end
    end
  end

  describe 'GET #live' do
    before do
      get live_league_auction_path(league, auction)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get live_league_auction_path(league, auction)
      end

      it { expect(response).to redirect_to(league_auction_transfers_path(league, auction)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get live_league_auction_path(league, auction)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:live) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get live_league_auction_path(league, auction)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:live) }
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
        get live_league_auction_path(league, auction, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:live) }
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
        get live_league_auction_path(league, auction, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:live) }
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

        expect(response).to redirect_to(league_auctions_path(league))
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

        expect(response).to redirect_to(league_auctions_path(league))
      end
    end
  end
end

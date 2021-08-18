RSpec.describe 'Transfers', type: :request do
  let(:league) { create(:league) }

  describe 'GET #index' do
    before do
      get league_transfers_path(league)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:transfers)).not_to be_nil }
  end

  describe 'GET #auction' do
    before do
      get league_auction_path(league)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get league_auction_path(league)
      end

      it { expect(response).to redirect_to(league_transfers_path(league)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get league_auction_path(league)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:auction) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get league_auction_path(league)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:auction) }
      it { expect(response).to render_template(:_header) }
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
        get league_auction_path(league, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:auction) }
      it { expect(response).to render_template(:_header) }
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
        get league_auction_path(league, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:auction) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
    end
  end

  describe 'POST #create' do
    let(:league) { create(:league, :with_five_teams) }
    let(:player) { create(:player) }
    let(:team) { league.teams.last }
    let(:price) { 13 }
    let(:params) do
      {
        transfer: {
          player_id: player.id,
          team_id: team.id,
          price: price
        }
      }
    end

    before do
      post league_transfers_path(league, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league, player: player)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with valid params when moderator is logged in' do
      login_moderator
      before do
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league)) }
      it { expect(response).to have_http_status(:found) }

      it 'creates transfer' do
        expect(Transfer.count).to eq(1)
      end

      it 'assigns player to team' do
        expect(player.teams.last).to eq(team)
      end

      it 'updates team budget' do
        expect(team.reload.budget).to eq(247)
      end
    end

    context 'with valid params when admin is logged in' do
      login_admin
      before do
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league)) }
      it { expect(response).to have_http_status(:found) }

      it 'creates transfer' do
        expect(Transfer.count).to eq(1)
      end

      it 'assigns player to team' do
        expect(player.teams.last).to eq(team)
      end

      it 'updates team budget' do
        expect(team.reload.budget).to eq(247)
      end
    end

    context 'with invalid team params' do
      let(:params) do
        {
          transfer: {
            player_id: player.id,
            team_id: '0',
            price: price
          }
        }
      end

      login_admin
      before do
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league, player: player)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not create transfer' do
        expect(Transfer.count).to eq(0)
      end

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(260)
      end
    end

    context 'with invalid player params' do
      let(:params) do
        {
          transfer: {
            player_id: '0',
            team_id: team.id,
            price: price
          }
        }
      end

      login_admin
      before do
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not create transfer' do
        expect(Transfer.count).to eq(0)
      end

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(260)
      end
    end

    context 'without vacancies at team squad' do
      let(:team) { create(:team, :with_players) }
      let(:league) { team.league }

      login_admin
      before do
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league, player: player)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not create transfer' do
        expect(Transfer.count).to eq(0)
      end

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(260)
      end
    end

    context 'with price bigger than max rate' do
      let(:price) { 240 }

      login_admin
      before do
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league, player: player)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not create transfer' do
        expect(Transfer.count).to eq(0)
      end

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(260)
      end
    end

    context 'with zero price' do
      let(:price) { 0 }

      login_admin
      before do
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league, player: player)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not create transfer' do
        expect(Transfer.count).to eq(0)
      end

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(260)
      end
    end

    context 'with invalid price' do
      let(:price) { 'invalid' }

      login_admin
      before do
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league, player: player)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not create transfer' do
        expect(Transfer.count).to eq(0)
      end

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(260)
      end
    end

    context 'without price' do
      let(:price) { nil }

      login_admin
      before do
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league, player: player)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not create transfer' do
        expect(Transfer.count).to eq(0)
      end

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(260)
      end
    end

    context 'when player already sold at this league' do
      login_admin
      before do
        create(:player_team, player: player, team: league.teams.first)
        post league_transfers_path(league, params)
      end

      it { expect(response).to redirect_to(league_auction_path(league)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not create transfer' do
        expect(Transfer.count).to eq(0)
      end

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(260)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:team) { create(:team, budget: 250) }
    let(:player_team) { create(:player_team, team: team) }
    let(:transfer) { create(:transfer, team: team, player: player_team.player, price: 10) }

    context 'when user is logged out' do
      before do
        delete league_transfer_path(transfer.league, transfer)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(250)
      end

      it 'does not remove player from team' do
        expect(player_team.reload).to eq(player_team)
      end

      it 'does not destroy transfer' do
        expect(transfer.reload).to eq(transfer)
      end
    end

    context 'when user is logged in' do
      login_user
      before do
        delete league_transfer_path(transfer.league, transfer)
      end

      it { expect(response).to redirect_to(league_auction_path(transfer.league)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(250)
      end

      it 'does not remove player from team' do
        expect(player_team.reload).to eq(player_team)
      end

      it 'does not destroy transfer' do
        expect(transfer.reload).to eq(transfer)
      end
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        delete league_transfer_path(transfer.league, transfer)
      end

      it { expect(response).to redirect_to(league_auction_path(transfer.league)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates team budget' do
        expect(team.reload.budget).to eq(260)
      end

      it 'removes player from team' do
        expect(PlayerTeam.find_by(id: player_team.id)).to be_nil
      end

      it 'destroys transfer' do
        expect(Transfer.find_by(id: transfer.id)).to be_nil
      end
    end

    context 'when admin is logged in' do
      login_admin
      before do
        delete league_transfer_path(transfer.league, transfer)
      end

      it { expect(response).to redirect_to(league_auction_path(transfer.league)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates team budget' do
        expect(team.reload.budget).to eq(260)
      end

      it 'removes player from team' do
        expect(PlayerTeam.find_by(id: player_team.id)).to be_nil
      end

      it 'destroys transfer' do
        expect(Transfer.find_by(id: transfer.id)).to be_nil
      end
    end

    context 'when admin is logged in but transfer is not exist' do
      login_admin
      before do
        delete league_transfer_path(transfer.league, 'invalid_id')
      end

      it { expect(response).to redirect_to(league_auction_path(transfer.league)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(250)
      end

      it 'does not remove player from team' do
        expect(player_team.reload).to eq(player_team)
      end
    end
  end
end

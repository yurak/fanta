RSpec.describe 'Players' do
  describe 'GET #index' do
    let(:players) { create_list(:player, 20) }
    let(:params) { nil }

    before do
      get players_path(params)
    end

    # context 'without params' do
    #   it { expect(response).to be_successful }
    #   it { expect(response).to render_template(:index) }
    #   it { expect(response).to render_template(:_paginator) }
    #   it { expect(response).to have_http_status(:ok) }
    #   it { expect(assigns(:players)).not_to be_nil }
    #   it { expect(assigns(:tournaments)).not_to be_nil }
    #   it { expect(assigns(:positions)).not_to be_nil }
    #   it { expect(assigns(:clubs)).not_to be_nil }
    # end

    # context 'with club order param' do
    #   let(:params) { { order: 'club' } }

    #   it { expect(response).to be_successful }
    #   it { expect(response).to render_template(:index) }
    #   it { expect(response).to render_template(:_paginator) }
    #   it { expect(response).to have_http_status(:ok) }
    #   it { expect(assigns(:players)).not_to be_nil }
    #   it { expect(assigns(:tournaments)).not_to be_nil }
    #   it { expect(assigns(:positions)).not_to be_nil }
    #   it { expect(assigns(:clubs)).not_to be_nil }
    # end

    # context 'with appearances order param' do
    #   let(:params) { { order: 'appearances' } }

    #   it { expect(response).to be_successful }
    #   it { expect(response).to render_template(:index) }
    #   it { expect(response).to render_template(:_paginator) }
    #   it { expect(response).to have_http_status(:ok) }
    #   it { expect(assigns(:players)).not_to be_nil }
    #   it { expect(assigns(:tournaments)).not_to be_nil }
    #   it { expect(assigns(:positions)).not_to be_nil }
    #   it { expect(assigns(:clubs)).not_to be_nil }
    # end

    # context 'with rating order param' do
    #   let(:params) { { order: 'rating' } }

    #   it { expect(response).to be_successful }
    #   it { expect(response).to render_template(:index) }
    #   it { expect(response).to render_template(:_paginator) }
    #   it { expect(response).to have_http_status(:ok) }
    #   it { expect(assigns(:players)).not_to be_nil }
    #   it { expect(assigns(:tournaments)).not_to be_nil }
    #   it { expect(assigns(:positions)).not_to be_nil }
    #   it { expect(assigns(:clubs)).not_to be_nil }
    # end
  end

  describe 'GET #show' do
    let(:club) { create(:club, name: 'Outside') }
    let(:player) { create(:player, club: club) }

    context 'with html format' do
      before do
        get player_path(player)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:player)).not_to be_nil }
    end

    context 'with json format' do
      before do
        params = { format: 'json' }
        get player_path(player, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:player)).not_to be_nil }

      it 'returns player id' do
        body = JSON(response.body)

        expect(body['id']).to eq(player.id)
      end

      it 'returns player name' do
        body = JSON(response.body)

        expect(body['name']).to eq(player.name)
      end

      it 'returns player avatar_path' do
        body = JSON(response.body)

        expect(body['avatar_path']).to eq(player.avatar_path)
      end
    end
  end

  describe 'PUT #update' do
    let(:team) { create(:team, budget: 250) }
    let(:player) { create(:player) }
    let!(:player_team) { create(:player_team, player: player, team: team) }
    let!(:transfer) { create(:transfer, team: team, player: player, price: 10) }

    context 'when user is logged out' do
      before do
        put player_path(player)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(250)
      end

      it 'does not remove player from team' do
        expect(player_team.reload).to eq(player_team)
      end

      it 'does not destroy initial transfer' do
        expect(transfer.reload).to eq(transfer)
      end

      it 'does not create left transfer' do
        expect(Transfer.left.count).to eq(0)
      end
    end

    context 'when user is logged in' do
      login_user
      before do
        put player_path(player)
      end

      it { expect(response).to redirect_to(player_path(player)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(250)
      end

      it 'does not remove player from team' do
        expect(player_team.reload).to eq(player_team)
      end

      it 'does not destroy initial transfer' do
        expect(transfer.reload).to eq(transfer)
      end

      it 'does not create left transfer' do
        expect(Transfer.left.count).to eq(0)
      end
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        put player_path(player)
      end

      it { expect(response).to redirect_to(player_path(player)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(250)
      end

      it 'does not remove player from team' do
        expect(player_team.reload).to eq(player_team)
      end

      it 'does not destroy initial transfer' do
        expect(transfer.reload).to eq(transfer)
      end

      it 'does not create left transfer' do
        expect(Transfer.left.count).to eq(0)
      end
    end

    context 'with valid conditions when admin is logged in' do
      login_admin
      before do
        create(:auction, league: team.league, status: :initial)

        put player_path(player)
      end

      it { expect(response).to redirect_to(player_path(player)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates team budget' do
        expect(team.reload.budget).to eq(260)
      end

      it 'removes player from team' do
        expect(team.players.find_by(id: player.id)).to be_nil
      end

      it 'does not destroy initial transfer' do
        expect(transfer.reload).to eq(transfer)
      end

      it 'creates left transfer' do
        expect(Transfer.left.count).to eq(1)
      end

      it 'calls Transfers::Seller service' do
        seller = instance_double(Transfers::Seller)
        allow(Transfers::Seller).to receive(:new).and_return(seller)
        allow(seller).to receive(:call)

        put player_path(player)

        expect(response).to redirect_to(player_path(player))
      end
    end

    context 'without suitable auction when admin is logged in' do
      login_admin
      before do
        put player_path(player)
      end

      it { expect(response).to redirect_to(player_path(player)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(250)
      end

      it 'does not remove player from team' do
        expect(player_team.reload).to eq(player_team)
      end

      it 'does not destroy initial transfer' do
        expect(transfer.reload).to eq(transfer)
      end

      it 'does not create left transfer' do
        expect(Transfer.left.count).to eq(0)
      end

      it 'calls Transfers::Seller service' do
        seller = instance_double(Transfers::Seller)
        allow(Transfers::Seller).to receive(:new).and_return(seller)
        allow(seller).to receive(:call)

        put player_path(player)

        expect(response).to redirect_to(player_path(player))
      end
    end

    context 'without initial transfer when admin is logged in' do
      let(:transfer) { nil }

      login_admin
      before do
        put player_path(player)
      end

      it { expect(response).to redirect_to(player_path(player)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update team budget' do
        expect(team.reload.budget).to eq(250)
      end

      it 'does not remove player from team' do
        expect(player_team.reload).to eq(player_team)
      end

      it 'does not create left transfer' do
        expect(Transfer.left.count).to eq(0)
      end

      it 'calls Transfers::Seller service' do
        seller = instance_double(Transfers::Seller)
        allow(Transfers::Seller).to receive(:new).and_return(seller)
        allow(seller).to receive(:call)

        put player_path(player)

        expect(response).to redirect_to(player_path(player))
      end
    end
  end
end

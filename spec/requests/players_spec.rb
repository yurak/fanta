RSpec.describe 'Players', type: :request do
  describe 'GET #index' do
    let(:players) { create_list(:player, 20) }
    let(:params) { nil }

    before do
      get players_path(params)
    end

    context 'without params' do
      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to render_template(:_paginator) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:tournaments)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with club order param' do
      let(:params) { { order: 'club' } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to render_template(:_paginator) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:tournaments)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with appearances order param' do
      let(:params) { { order: 'appearances' } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to render_template(:_paginator) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:tournaments)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with rating order param' do
      let(:params) { { order: 'rating' } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to render_template(:_paginator) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:tournaments)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end
  end

  describe 'GET #show' do
    let(:club) { create(:club, name: 'xxx') }
    let(:player) { create(:player, club: club) }

    context 'with html format' do
      before do
        get player_path(player)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to render_template(:_header) }
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

        expect(body['name']).to eq(player.name.upcase)
      end

      it 'returns player avatar_path' do
        body = JSON(response.body)

        expect(body['avatar_path']).to eq(player.avatar_path)
      end
    end
  end
end

RSpec.describe 'RoundPlayers', type: :request do
  describe 'GET #index' do
    let(:tournament_round) { create(:tournament_round) }
    let(:params) { nil }

    before do
      get tournament_round_round_players_path(tournament_round, params)
    end

    context 'without additional params' do
      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with national tournament' do
      let(:tournament_round) { create(:tournament_round, tournament: create(:tournament, :with_national_teams)) }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with eurocup tournament' do
      let(:tournament_round) { create(:tournament_round, :with_eurocup_tournament) }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with position param' do
      let(:params) { { position: 'T' } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with club order param' do
      let(:params) { { order: 'club' } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with national order param' do
      let(:params) { { order: 'national' } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with matches order param' do
      let(:params) { { order: 'matches' } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with name order param' do
      let(:params) { { order: 'name' } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with base_score order param' do
      let(:params) { { order: 'base_score' } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end
  end
end

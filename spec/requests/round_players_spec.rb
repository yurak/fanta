RSpec.describe 'RoundPlayers' do
  describe 'GET #index' do
    let(:tournament_round) { create(:tournament_round) }
    let(:params) { nil }

    context 'when user is logged out' do
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'without additional params' do
      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with national tournament' do
      let(:tournament_round) { create(:tournament_round, tournament: create(:tournament, :with_national_teams)) }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with eurocup tournament' do
      let(:tournament_round) { create(:tournament_round, :with_eurocup_tournament) }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with position param' do
      let(:params) { { position: 'T' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with national tournament and position param' do
      let(:tournament_round) { create(:tournament_round, tournament: create(:tournament, :with_national_teams)) }
      let(:params) { { position: 'T' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with eurocup tournament and position param' do
      let(:tournament_round) { create(:tournament_round, :with_eurocup_tournament) }
      let(:params) { { position: 'T' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with club order param' do
      let(:params) { { order: 'club' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with national order param' do
      let(:params) { { order: 'national' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with matches order param' do
      let(:params) { { order: 'matches' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with main_squad order param' do
      let(:params) { { order: 'main_squad' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with name order param' do
      let(:params) { { order: 'name' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with base_score order param' do
      let(:params) { { order: 'base_score' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end
  end
end

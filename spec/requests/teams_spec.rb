RSpec.describe 'Teams', type: :request do
  let(:team) { create(:team) }

  describe 'GET #show' do
    let(:team) { create(:team, :with_league_matches) }

    before do
      get team_path(team)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response).to have_http_status(:ok) }
  end

  describe 'GET #new' do
    context 'when user is logged out' do
      before do
        get new_team_path
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get new_team_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'POST #create' do
    let(:human_name) { 'Forza' }
    let(:logo_url) { 'forza.png' }
    let(:params) do
      {
        team: {
          human_name: human_name,
          logo_url: logo_url
        }
      }
    end

    context 'when user is logged out' do
      before do
        post teams_path(params)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      let(:logged_user) { create(:user, status: 'with_avatar') }

      before do
        sign_in logged_user
        post teams_path(params)
      end

      context 'with valid params' do
        it { expect(response).to redirect_to(new_join_request_path) }
        it { expect(response).to have_http_status(:found) }

        it 'creates team with specified human_name' do
          expect(Team.last.human_name).to eq(human_name)
        end

        it 'creates team with specified logo_url' do
          expect(Team.last.logo_url).to eq(logo_url)
        end

        it 'updates team user status' do
          expect(logged_user.reload.status).to eq('with_team')
        end
      end

      context 'with invalid params' do
        let(:human_name) { '' }

        it { expect(response).to be_successful }
        it { expect(response).to render_template(:new) }
        it { expect(response).to have_http_status(:ok) }
      end
    end
  end

  describe 'GET #edit' do
    before do
      get edit_team_path(team)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team) }

      before do
        sign_in logged_user
        get edit_team_path(team)
      end

      it { expect(response).to redirect_to(user_path(logged_user)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }

      before do
        sign_in logged_user
        get edit_team_path(team)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:team)).not_to be_nil }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:logged_user) { create(:user) }
    let(:team) { create(:team, user: logged_user) }
    let(:human_name) { 'Forza' }
    let(:logo_url) { 'forza.png' }
    let(:params) do
      {
        team: {
          human_name: human_name,
          logo_url: logo_url
        }
      }
    end

    before do
      put team_path(team, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      let(:team) { create(:team) }

      before do
        sign_in logged_user
        put team_path(team, params)
      end

      it { expect(response).to redirect_to(user_path(logged_user)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and invalid params when user is logged in' do
      let(:human_name) { 'Forza Milan! Forza Milan! Forza Milan! Forza Milan!' }

      before do
        sign_in logged_user
        put team_path(team, params)
      end

      it { expect(response).to render_template(:new) }
      it { expect(response).to have_http_status(:ok) }

      it 'does not update team human_name' do
        expect(team.reload.human_name).to eq(team.human_name)
      end

      it 'does not update team logo_url' do
        expect(team.reload.logo_url).to eq(team.logo_url)
      end
    end

    context 'with own team and valid params when user is logged in' do
      before do
        sign_in logged_user
        put team_path(team, params)
      end

      it { expect(response).to redirect_to(user_path(logged_user)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates team human_name' do
        expect(team.reload.human_name).to eq(human_name)
      end

      it 'updates team logo_url' do
        expect(team.reload.logo_url).to eq(logo_url)
      end
    end
  end
end

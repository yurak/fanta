RSpec.describe 'Users', type: :request do
  let(:other_user) { create(:user) }

  describe 'GET #show' do
    before do
      get user_path(other_user)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in and show self data' do
      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user)
        create(:tour, league: team.league)
        sign_in logged_user
        get user_path(logged_user)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when user is logged in and show other user data' do
      login_user
      before do
        get user_path(other_user)
      end

      it { expect(response).to redirect_to(user_path(User.last)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'GET #edit' do
    before do
      get edit_user_path(other_user)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in and show self edit page' do
      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user)
        create(:tour, league: team.league)
        sign_in logged_user
        get edit_user_path(logged_user)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when user is logged in and show other user edit page' do
      login_user
      before do
        get edit_user_path(other_user)
      end

      it { expect(response).to redirect_to(user_path(User.last)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'GET #edit_avatar' do
    before do
      get edit_avatar_user_path(other_user)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in and show self edit avatar page' do
      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user)
        create(:tour, league: team.league)
        sign_in logged_user
        get edit_avatar_user_path(logged_user)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit_avatar) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when user is logged in and show other user edit avatar page' do
      login_user
      before do
        get edit_avatar_user_path(other_user)
      end

      it { expect(response).to redirect_to(user_path(User.last)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:name) { FFaker::Name.first_name }
    let(:params) { { name: name } }

    before do
      patch user_path(other_user, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in and updates self data' do
      login_user
      before do
        patch user_path(User.last, params)
      end

      it { expect(response).to redirect_to(user_path) }
      it { expect(response).to have_http_status(:found) }

      it 'updates user name' do
        expect(User.last.reload.name).to eq(name)
      end
    end

    context 'when user is logged in and updates active_team_id' do
      let(:active_team_id) { 3 }
      let(:params) { { active_team_id: active_team_id } }

      login_user
      before do
        patch user_path(User.last, params)
      end

      it { expect(response).to redirect_to(root_path) }
      it { expect(response).to have_http_status(:found) }

      it 'updates user name' do
        expect(User.last.reload.active_team_id).to eq(active_team_id)
      end
    end

    context 'when user is logged in and updates other user data' do
      login_user
      before do
        patch user_path(other_user, params)
      end

      it { expect(response).to have_http_status(:found) }
      it { expect(response).to redirect_to(user_path(User.last)) }

      it 'does not update other user name' do
        expect(other_user.reload.name).not_to eq(name)
      end
    end
  end
end

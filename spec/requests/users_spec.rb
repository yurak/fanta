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
    let(:params) { nil }

    before do
      patch user_path(other_user, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in and updates self data' do
      let(:logged_user) { create(:user) }
      let(:name) { FFaker::Name.first_name }
      let(:params) { { name: name } }

      before do
        sign_in logged_user

        patch user_path(logged_user, params)
      end

      it { expect(response).to redirect_to(user_path) }
      it { expect(response).to have_http_status(:found) }

      it 'updates user name' do
        expect(logged_user.reload.name).to eq(name)
      end
    end

    context 'when user is logged in and updates active_team_id with active tour' do
      let(:logged_user) { create(:user) }
      let(:active_team) { create(:team, user: logged_user) }
      let!(:tour) { create(:tour, league: active_team.league) }
      let(:params) { { active_team_id: active_team.id } }

      before do
        sign_in logged_user

        patch user_path(logged_user, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates user active_team_id' do
        expect(logged_user.reload.active_team_id).to eq(active_team.id)
      end
    end

    context 'when user is logged in and updates active_team_id without active tour' do
      let(:logged_user) { create(:user) }
      let(:active_team) { create(:team, user: logged_user) }
      let(:params) { { active_team_id: active_team.id } }

      before do
        sign_in logged_user

        patch user_path(logged_user, params)
      end

      it { expect(response).to redirect_to(league_path(active_team.league)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates user active_team_id' do
        expect(logged_user.reload.active_team_id).to eq(active_team.id)
      end
    end

    context 'when user is logged in and updates other user data' do
      let(:name) { FFaker::Name.first_name }
      let(:params) { { name: name } }
      let(:logged_user) { create(:user) }

      before do
        sign_in logged_user

        patch user_path(other_user, params)
      end

      it { expect(response).to have_http_status(:found) }
      it { expect(response).to redirect_to(user_path(logged_user)) }

      it 'does not update other user name' do
        expect(other_user.reload.name).not_to eq(name)
      end
    end
  end

  describe 'GET #new_name' do
    before do
      get new_name_user_path(other_user)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in and show self new name page' do
      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user)
        create(:tour, league: team.league)
        sign_in logged_user
        get new_name_user_path(logged_user)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new_name) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when user is logged in and show other user new name page' do
      login_user
      before do
        get new_name_user_path(other_user)
      end

      it { expect(response).to redirect_to(user_path(User.last)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when initial user is logged in and redirected to new name page' do
      let(:user) { create(:user, status: :initial) }

      before do
        sign_in user
        get new_avatar_user_path(user)
      end

      it { expect(response).to redirect_to(new_name_user_path(user)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'GET #new_avatar' do
    before do
      get new_avatar_user_path(other_user)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in and show self new avatar page' do
      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user)
        create(:tour, league: team.league)
        sign_in logged_user
        get new_avatar_user_path(logged_user)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new_avatar) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when user is logged in and show other user new avatar page' do
      login_user
      before do
        get new_avatar_user_path(other_user)
      end

      it { expect(response).to redirect_to(user_path(User.last)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when named user is logged in and redirected to new avatar page' do
      let(:user) { create(:user, status: :named) }

      before do
        sign_in user
        get new_name_user_path(user)
      end

      it { expect(response).to redirect_to(new_avatar_user_path(user)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when with_avatar user is logged in' do
      let(:user) { create(:user, status: :with_avatar) }

      before do
        sign_in user
        get new_name_user_path(user)
      end

      it { expect(response).to redirect_to(new_team_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when with_team user is logged in' do
      let(:user) { create(:user, status: :with_team) }

      before do
        sign_in user
        get new_name_user_path(user)
      end

      it { expect(response).to redirect_to(new_join_request_path) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'PUT #new_update' do
    let(:params) { nil }

    before do
      put new_update_user_path(other_user, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when initial user is logged in and updates self name' do
      let(:logged_user) { create(:user, name: '', status: :initial) }
      let(:name) { FFaker::Name.first_name }
      let(:params) { { name: name } }

      before do
        sign_in logged_user

        put new_update_user_path(logged_user, params)
      end

      it { expect(response).to redirect_to(new_avatar_user_path(logged_user)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates user name' do
        expect(logged_user.reload.name).to eq(name)
      end

      it 'updates user status' do
        expect(logged_user.reload.status).to eq('named')
      end
    end

    context 'when initial user is logged in and updates self avatar' do
      let(:logged_user) { create(:user, name: '', status: :initial) }
      let(:avatar) { '3' }
      let(:params) { { avatar: avatar } }

      before do
        sign_in logged_user

        put new_update_user_path(logged_user, params)
      end

      it { expect(response).to redirect_to(new_name_user_path(logged_user)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update avatar' do
        expect(logged_user.reload.avatar).to eq(logged_user.avatar)
      end
    end

    context 'when named user is logged in and updates self name' do
      let(:logged_user) { create(:user, status: :named) }
      let(:name) { FFaker::Name.first_name }
      let(:params) { { name: name } }

      before do
        sign_in logged_user

        put new_update_user_path(logged_user, params)
      end

      it { expect(response).to redirect_to(new_avatar_user_path(logged_user)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update user name' do
        expect(logged_user.reload.name).to eq(logged_user.name)
      end
    end

    context 'when named user is logged in and updates self avatar' do
      let(:logged_user) { create(:user, status: :named) }
      let(:avatar) { '3' }
      let(:params) { { avatar: avatar } }

      before do
        sign_in logged_user

        put new_update_user_path(logged_user, params)
      end

      it { expect(response).to redirect_to(new_team_path) }
      it { expect(response).to have_http_status(:found) }

      it 'updates user avatar' do
        expect(logged_user.reload.avatar).to eq(avatar)
      end

      it 'updates user status' do
        expect(logged_user.reload.status).to eq('with_avatar')
      end
    end

    context 'when user is logged in and updates other user data' do
      let(:name) { FFaker::Name.first_name }
      let(:params) { { name: name } }
      let(:logged_user) { create(:user) }

      before do
        sign_in logged_user

        put new_update_user_path(other_user, params)
      end

      it { expect(response).to have_http_status(:found) }
      it { expect(response).to redirect_to(user_path(logged_user)) }

      it 'does not update other user name' do
        expect(other_user.reload.name).not_to eq(name)
      end
    end
  end
end

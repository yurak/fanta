RSpec.describe 'Manage::Users' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_users_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_users_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      let!(:user_one) { create(:user, email: 'alice@example.com', name: 'Alice') }

      before do
        create(:user, email: 'bob@example.com', name: 'Bob')
        get manage_users_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'shows alice when no filter' do
        expect(response.body).to include('alice@example.com')
      end

      it 'shows bob when no filter' do
        expect(response.body).to include('bob@example.com')
      end

      it 'shows newest users first' do
        alice_pos = response.body.index('alice@example.com')
        bob_pos = response.body.index('bob@example.com')
        expect(bob_pos).to be < alice_pos
      end

      it 'filters by id — shows match' do
        get manage_users_path, params: { id: user_one.id }
        expect(response.body).to include('alice@example.com')
      end

      it 'filters by id — hides non-match' do
        get manage_users_path, params: { id: user_one.id }
        expect(response.body).not_to include('bob@example.com')
      end

      it 'filters by email — shows match' do
        get manage_users_path, params: { email: 'alice' }
        expect(response.body).to include('alice@example.com')
      end

      it 'filters by email — hides non-match' do
        get manage_users_path, params: { email: 'alice' }
        expect(response.body).not_to include('bob@example.com')
      end

      it 'shows reset link when filter is applied' do
        get manage_users_path, params: { email: 'alice' }
        expect(response.body).to include(manage_users_path)
      end
    end
  end

  describe 'GET #show' do
    let(:user) { create(:user, name: 'Charlie', email: 'charlie@example.com') }

    context 'when user is logged out' do
      before { get manage_user_path(user) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_user_path(user) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      before { get manage_user_path(user) }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }

      it 'displays user email' do
        expect(response.body).to include('charlie@example.com')
      end

      it 'displays user name' do
        expect(response.body).to include('Charlie')
      end
    end

    context 'when user has teams' do
      login_admin

      before do
        create(:team, user: user, human_name: 'Charlies FC')
        get manage_user_path(user)
      end

      it 'shows the team' do
        expect(response.body).to include('Charlies FC')
      end
    end
  end
end

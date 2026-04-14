RSpec.describe 'Manage::Teams' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_teams_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_teams_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      before do
        create(:team, human_name: 'Alpha Team')
        create(:team, human_name: 'Beta Team')
        get manage_teams_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'shows Alpha Team when no filter' do
        expect(response.body).to include('Alpha Team')
      end

      it 'shows Beta Team when no filter' do
        expect(response.body).to include('Beta Team')
      end

      it 'filters teams by name — shows match' do
        get manage_teams_path, params: { name: 'Alpha' }
        expect(response.body).to include('Alpha Team')
      end

      it 'filters teams by name — hides non-match' do
        get manage_teams_path, params: { name: 'Alpha' }
        expect(response.body).not_to include('Beta Team')
      end

      it 'shows reset link when name filter is applied' do
        get manage_teams_path, params: { name: 'Alpha' }
        expect(response.body).to include(manage_teams_path)
      end

      it 'shows newest teams first' do
        alpha_pos = response.body.index('Alpha Team')
        beta_pos = response.body.index('Beta Team')
        expect(beta_pos).to be < alpha_pos
      end
    end
  end
end

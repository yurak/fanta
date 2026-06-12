RSpec.describe 'Manage::NationalTeams' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_national_teams_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_national_teams_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      before do
        create(:national_team, name: 'AlphaNT')
        create(:national_team, name: 'BetaNT')
        get manage_national_teams_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'shows AlphaNT when no filter' do
        expect(response.body).to include('AlphaNT')
      end

      it 'shows BetaNT when no filter' do
        expect(response.body).to include('BetaNT')
      end

      it 'filters by name — shows match' do
        get manage_national_teams_path, params: { name: 'AlphaNT' }
        expect(response.body).to include('AlphaNT')
      end

      it 'filters by name — hides non-match' do
        get manage_national_teams_path, params: { name: 'AlphaNT' }
        expect(response.body).not_to include('BetaNT')
      end
    end
  end

  describe 'GET #show' do
    context 'when user is logged out' do
      let(:national_team) { create(:national_team) }

      before { get manage_national_team_path(national_team) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when admin is logged in' do
      login_admin

      let(:national_team) { create(:national_team, name: 'France') }

      before do
        create(:player, national_team: national_team, name: 'Dupont')
        get manage_national_team_path(national_team)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }

      it 'displays team name' do
        expect(response.body).to include('France')
      end

      it 'displays players' do
        expect(response.body).to include('Dupont')
      end
    end
  end
end

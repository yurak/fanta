RSpec.describe 'NationalTeams' do
  describe 'GET #show' do
    let(:national_team) { create(:national_team) }

    context 'when user is logged out' do
      before do
        get national_team_path(national_team)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user

      before do
        get national_team_path(national_team)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when user has a team in the tournament' do
      let(:logged_user) { create(:user) }
      let(:league) { create(:league, tournament: national_team.tournament) }

      before do
        create(:team, user: logged_user, league: league)
        sign_in logged_user
        get national_team_path(national_team)
      end

      it { expect(response).to be_successful }
    end

    context 'when user has no team in the tournament' do
      let(:logged_user) { create(:user) }

      before do
        sign_in logged_user
        get national_team_path(national_team)
      end

      it { expect(response).to be_successful }
    end
  end
end

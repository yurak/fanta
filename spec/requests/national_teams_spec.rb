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
  end
end

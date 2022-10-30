RSpec.describe 'NationalTeams' do
  describe 'GET #show' do
    let(:national_team) { create(:national_team) }

    before do
      get national_team_path(national_team)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response).to have_http_status(:ok) }
  end
end

RSpec.describe 'Teams', type: :request do
  describe 'GET #show' do
    let(:team) { create(:team) }

    before do
      get team_path(team)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to have_http_status(:ok) }
  end
end

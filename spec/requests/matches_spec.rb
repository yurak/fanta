RSpec.describe 'Matches' do
  describe 'GET #show' do
    let(:match1) { create(:match) }

    before do
      get match_path(match1)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response).to render_template(:_team_squad) }
    it { expect(response).to have_http_status(:ok) }
  end
end

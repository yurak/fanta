RSpec.describe 'Results', type: :request do
  describe 'GET #index' do
    let(:league) { create(:league) }

    before do
      get league_results_path(league)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:results)).not_to be_nil }
  end
end

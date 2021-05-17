RSpec.describe 'Tournaments', type: :request do
  let(:tournament) { create(:tournament) }

  describe 'GET #show' do
    before do
      get tournament_path(tournament)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:tournament)).not_to be_nil }
  end
end

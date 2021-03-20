RSpec.describe 'League', type: :request do
  describe 'GET #index' do
    before do
      get leagues_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to have_http_status(:ok) }
  end
end

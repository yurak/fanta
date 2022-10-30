RSpec.describe 'Links' do
  describe 'GET #index' do
    before do
      get links_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:links)).not_to be_nil }
  end
end

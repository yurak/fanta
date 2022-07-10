RSpec.describe 'Users::Confirmations', type: :request do
  describe 'GET #index' do
    let(:user) { create(:user) }

    before do
      get users_confirmations_path(user: user)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:email)).to eq(user.email) }
  end
end

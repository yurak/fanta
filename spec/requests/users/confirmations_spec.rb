RSpec.describe 'Users::Confirmations' do
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

  describe 'GET #show (email confirmation)' do
    let(:user) { create(:user, confirmed_at: nil, confirmation_token: nil) }
    let(:raw_token) do
      user.send(:generate_confirmation_token!)
      user.instance_variable_get(:@raw_confirmation_token)
    end

    before { get user_confirmation_path(confirmation_token: raw_token) }

    it { expect(response).to have_http_status(:found) }

    it { expect(response.location).to include(edit_user_password_path) }
    it { expect(response.location).to include('reset_password_token=') }

    it 'confirms the user' do
      expect(user.reload.confirmed?).to be true
    end

    context 'when token is invalid' do
      let(:raw_token) { 'invalid_token' }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template(:new) }
    end
  end
end

RSpec.describe 'Subscriptions' do
  describe 'GET #unsubscribe' do
    let(:token) { SecureRandom.hex(16) }

    before do
      get unsubscribe_path(token: token)
    end

    context 'without token' do
      before do
        get unsubscribe_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:unsubscribe) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'with invalid token' do
      it { expect(response).to be_successful }
      it { expect(response).to render_template(:unsubscribe) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'with valid token' do
      let(:token) { create(:user).unsubscribe_token }

      before do
        get unsubscribe_path(token: token)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:unsubscribe) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'POST #confirm_unsubscribe' do
    let(:token) { SecureRandom.hex(16) }
    # let(:params) { { token: token } }

    before do
      post unsubscribe_path(token: token)
    end

    context 'without token' do
      before do
        post unsubscribe_path
      end

      it { expect(response).to redirect_to(root_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with invalid token' do
      it { expect(response).to redirect_to(root_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with valid token' do
      let(:user) { create(:user) }
      let(:token) { user.unsubscribe_token }

      before do
        post unsubscribe_path(token: token)
      end

      it { expect(response).to redirect_to(root_path) }
      it { expect(response).to have_http_status(:found) }

      it 'unsubscribes user' do
        expect(user.reload.subscribed).to be_falsey
      end
    end
  end
end

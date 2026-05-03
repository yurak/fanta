RSpec.describe 'Users::Registrations' do
  let(:email)    { FFaker::Internet.safe_email[0...50] }
  let(:password) { FFaker::Internet.password }
  let(:params) do
    {
      user: {
        name: FFaker::Name.first_name[0...15],
        email: email,
        password: password,
        password_confirmation: password
      }
    }
  end

  describe 'GET /users/sign_up' do
    context 'when email param is passed (coming from bot link)' do
      before { get new_user_registration_path, params: { email: email } }

      it 'pre-fills the email field' do
        expect(response.body).to include(email)
      end
    end

    context 'when tg_token param is present' do
      before { get new_user_registration_path, params: { email: email, tg_token: 'abc123' } }

      it 'renders a hidden field with the token name' do
        expect(response.body).to include('name="tg_token"')
      end

      it 'renders a hidden field with the token value' do
        expect(response.body).to include('value="abc123"')
      end
    end

    context 'when tg_token param is absent' do
      before { get new_user_registration_path }

      it 'does not render a hidden tg_token field' do
        expect(response.body).not_to include('name="tg_token"')
      end
    end
  end

  describe 'POST /users' do
    context 'with valid params' do
      before { post user_registration_path, params: params }

      it { expect(response).to have_http_status(:found) }

      it 'creates the user' do
        expect(User.find_by(email: email)).to be_present
      end

      it 'redirects to the confirmations page for the new user' do
        user = User.find_by!(email: email)
        expect(response).to redirect_to(users_confirmations_path(user: user))
      end

      it 'leaves the user unconfirmed' do
        expect(User.find_by!(email: email).confirmed_at).to be_nil
      end
    end

    context 'with valid params and tg_token (Flow 1: bot → registration)' do
      let(:chat_id) { 99_999 }
      let(:token) { 'test_tg_token' }

      before do
        Rails.cache.write("tg_connect:#{token}", chat_id, expires_in: 1.hour)
        post user_registration_path, params: params.merge(tg_token: token)
      end

      it 'links tg_chat_id to the user profile' do
        user = User.find_by!(email: email)
        expect(user.user_profile.tg_chat_id).to eq(chat_id)
      end

      it 'enables bot for the user' do
        user = User.find_by!(email: email)
        expect(user.user_profile.bot_enabled).to be(true)
      end

      it 'removes the token from cache' do
        expect(Rails.cache.read("tg_connect:#{token}")).to be_nil
      end
    end

    context 'with invalid params (email already taken)' do
      before do
        create(:user, email: email)
        post user_registration_path, params: params
      end

      it { expect(response).to have_http_status(:ok) }

      it 'does not create a duplicate user' do
        expect(User.where(email: email).count).to eq(1)
      end

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end
    end
  end
end

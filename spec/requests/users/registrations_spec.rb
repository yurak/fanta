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

    context 'with invalid params (email already taken)' do
      let!(:existing_user) { create(:user, email: email) }

      before { post user_registration_path, params: params }

      it 'does not create a duplicate user' do
        expect(User.where(email: email).count).to eq(1)
      end

      it 'does not redirect to the confirmations page' do
        expect(response).not_to redirect_to(users_confirmations_path(user: existing_user))
      end
    end
  end
end

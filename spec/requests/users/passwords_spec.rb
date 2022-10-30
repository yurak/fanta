RSpec.describe 'Users::Passwords' do
  describe 'GET #index' do
    let(:email) { FFaker::Internet.safe_email[0...50] }

    before do
      get users_passwords_path(email: email)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:email)).to eq(email) }
  end
end

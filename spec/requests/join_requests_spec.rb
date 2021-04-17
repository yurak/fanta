RSpec.describe 'JoinRequests', type: :request do
  describe 'GET #new' do
    before do
      get new_join_request_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:new) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to have_http_status(:ok) }
    it { expect(assigns(:join_request)).not_to be_nil }
  end

  describe 'POST #create' do
    let(:username) { FFaker::Name.first_name }
    let(:params) do
      {
        join_request: {
          username: username,
          email: FFaker::Internet.safe_email,
          contact: FFaker::Internet.safe_email
        }
      }
    end

    before do
      post join_requests_path(params)
    end

    context 'with valid params' do
      let(:join_request) { JoinRequest.find_by(username: username) }

      it { expect(response).to redirect_to(success_request_path) }
      it { expect(response).to have_http_status(:found) }

      it 'creates join_request with specified username' do
        expect(join_request.username).to eq(username)
      end
    end

    context 'with invalid params' do
      let(:username) { '' }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'GET #success_request' do
    before do
      get success_request_path
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:success_request) }
    it { expect(response).to render_template(:_header) }
    it { expect(response).to have_http_status(:ok) }
  end
end

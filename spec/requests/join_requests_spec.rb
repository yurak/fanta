RSpec.describe 'JoinRequests' do
  describe 'GET #new' do
    context 'when user is logged out' do
      before do
        get new_join_request_path
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get new_join_request_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'POST #create' do
    let(:leagues) { ['1'] }
    let(:params) do
      {
        join_request: {
          leagues: leagues
        }
      }
    end

    context 'when user is logged out' do
      before do
        post join_requests_path(params)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        post join_requests_path(params)
      end

      context 'with valid params' do
        it { expect(response).to redirect_to(join_requests_path) }
        it { expect(response).to have_http_status(:found) }

        it 'creates join_request with specified leagues' do
          expect(JoinRequest.last.leagues).to eq(leagues.to_json)
        end
      end

      context 'with invalid params' do
        let(:leagues) { '' }

        it { expect(response).to be_successful }
        it { expect(response).to render_template(:new) }
        it { expect(response).to have_http_status(:ok) }
      end
    end
  end

  describe 'GET #index' do
    context 'when user is logged out' do
      before do
        get join_requests_path
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when configured user is logged in' do
      login_user
      before do
        get join_requests_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
    end
  end
end

RSpec.describe 'Leagues' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before do
        get leagues_path
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get leagues_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'GET #show' do
    let(:league) { create(:league) }

    context 'when user is logged out' do
      before do
        get league_path(league)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get league_path(league)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:league)).not_to be_nil }
      it { expect(assigns(:league)).to eq(league) }
    end
  end
end

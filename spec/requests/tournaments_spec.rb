RSpec.describe 'Tournaments' do
  let(:tournament) { create(:tournament) }

  describe 'GET #show' do
    context 'when user is logged out' do
      before do
        get tournament_path(tournament)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get tournament_path(tournament)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:tournament)).not_to be_nil }
    end
  end
end

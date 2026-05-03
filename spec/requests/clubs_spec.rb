RSpec.describe 'Clubs' do
  describe 'GET #show' do
    let(:club) { create(:club) }

    context 'when user is logged out' do
      before do
        get tournament_club_path(club.tournament, club)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get tournament_club_path(club.tournament, club)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
    end
  end
end

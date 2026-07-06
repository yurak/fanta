RSpec.describe 'Manage::ClubTransfers' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_club_transfers_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user
      before { get manage_club_transfers_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      let!(:transfer) { create(:club_transfer, new_club_name: 'MarkerClubX') }

      before { get manage_club_transfers_path }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response.body).to include('MarkerClubX') }

      it 'filters by player name' do
        get manage_club_transfers_path, params: { player_name: transfer.player.name }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

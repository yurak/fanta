RSpec.describe 'Manage::ClubTransfers' do
  describe 'POST #create' do
    let(:tournament) { create(:tournament) }
    let(:old_club) { create(:club, tournament: tournament) }
    let(:new_club) { create(:club, tournament: tournament) }
    let(:player) { create(:player, club: old_club) }
    let(:valid_params) do
      {
        new_club_id: new_club.id,
        start_date: Time.zone.today.to_s,
        contract_expires_on: '2027-06-30',
        loan: '0'
      }
    end

    context 'when user is logged out' do
      before { post manage_player_club_transfers_path(player), params: valid_params }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { post manage_player_club_transfers_path(player), params: valid_params }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      context 'with valid params' do
        before do
          allow(Players::ClubChanger).to receive(:call).and_return(true)
          post manage_player_club_transfers_path(player), params: valid_params
        end

        it { expect(response).to redirect_to(manage_player_path(player)) }
        it { expect(flash[:notice]).to be_present }

        it 'calls Players::ClubChanger with correct params' do
          expect(Players::ClubChanger).to have_received(:call).with(
            hash_including(player: player, new_club_id: new_club.id.to_s, loan: false)
          )
        end
      end

      context 'when Players::ClubChanger returns false' do
        before do
          allow(Players::ClubChanger).to receive(:call).and_return(false)
          post manage_player_club_transfers_path(player), params: valid_params
        end

        it { expect(response).to redirect_to(manage_player_path(player)) }
        it { expect(flash[:alert]).to be_present }
      end
    end
  end
end

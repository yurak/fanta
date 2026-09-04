RSpec.describe 'Manage::RoundPlayers' do
  let(:tournament) { create(:tournament) }
  let(:club) { create(:club, tournament: tournament) }
  let(:player) { create(:player, club: club) }
  let!(:round) { create(:tournament_round, tournament: tournament, season: Season.last, number: 7) }

  describe 'POST #create' do
    context 'when logged out' do
      before { post manage_round_players_path, params: { player_id: player.id, number: 7 } }

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(RoundPlayer.count).to eq(0) }
    end

    context 'when admin is logged in' do
      login_admin

      it 'creates a round player' do
        expect { post manage_round_players_path, params: { player_id: player.id, number: 7 } }
          .to change(RoundPlayer, :count).by(1)
      end

      context 'with the created round player' do
        before { post manage_round_players_path, params: { player_id: player.id, number: 7 } }

        it { expect(RoundPlayer.last.tournament_round).to eq(round) }
        it { expect(RoundPlayer.last.club).to eq(club) }
        it { expect(RoundPlayer.last.player).to eq(player) }
      end

      it 'redirects back to the player page' do
        post manage_round_players_path, params: { player_id: player.id, number: 7 }

        expect(response).to redirect_to(manage_player_path(player))
      end

      it 'does not create a duplicate for the same round' do
        create(:round_player, player: player, tournament_round: round, club: club)

        expect { post manage_round_players_path, params: { player_id: player.id, number: 7 } }
          .not_to change(RoundPlayer, :count)
      end

      it 'reports a missing round' do
        post manage_round_players_path, params: { player_id: player.id, number: 99 }

        expect(flash[:alert]).to eq(I18n.t('manage.round_players.round_not_found', number: '99'))
      end
    end
  end

  describe 'GET #edit' do
    login_admin

    let(:round_player) { create(:round_player, player: player, tournament_round: round, club: club) }

    before { get edit_manage_round_player_path(round_player) }

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:edit) }
  end

  describe 'PATCH #update' do
    login_admin

    let(:round_player) { create(:round_player, player: player, tournament_round: round, club: club) }
    let(:other_round) { create(:tournament_round, tournament: tournament, season: Season.last, number: 8) }
    let(:other_club) { create(:club, tournament: tournament) }

    context 'with a changed round and club' do
      before do
        patch manage_round_player_path(round_player),
              params: { round_player: { tournament_round_id: other_round.id, club_id: other_club.id } }
      end

      it { expect(round_player.reload.tournament_round).to eq(other_round) }
      it { expect(round_player.reload.club).to eq(other_club) }
    end

    it 'redirects to the player page' do
      patch manage_round_player_path(round_player),
            params: { round_player: { tournament_round_id: other_round.id, club_id: other_club.id } }

      expect(response).to redirect_to(manage_player_path(player))
    end
  end
end

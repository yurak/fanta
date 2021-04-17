RSpec.describe 'MatchPlayers', type: :request do
  describe 'PUT/PATCH #update' do
    let(:match_player) { create(:match_player) }
    let(:params) { { cleansheet: true } }

    before do
      put match_player_path(match_player, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        create(:match, tour: match_player.lineup.tour, host: match_player.lineup.team)
        put match_player_path(match_player, params)
      end

      it { expect(response).to redirect_to(match_path) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update match_player cleansheet' do
        expect(match_player.reload.cleansheet).to eq(false)
      end
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        create(:match, tour: match_player.lineup.tour, host: match_player.lineup.team)
        put match_player_path(match_player, params)
      end

      it { expect(response).to redirect_to(match_path) }
      it { expect(response).to have_http_status(:found) }

      it 'updates match_player cleansheet' do
        expect(match_player.reload.cleansheet).to eq(true)
      end
    end

    context 'when admin is logged in' do
      login_admin
      before do
        create(:match, tour: match_player.lineup.tour, host: match_player.lineup.team)
        put match_player_path(match_player, params)
      end

      it { expect(response).to redirect_to(match_path) }
      it { expect(response).to have_http_status(:found) }

      it 'updates match_player cleansheet' do
        expect(match_player.reload.cleansheet).to eq(true)
      end
    end

    context 'with invalid params when admin is logged in' do
      login_admin
      before do
        create(:match, tour: match_player.lineup.tour, host: match_player.lineup.team)
        put match_player_path(match_player, params)
      end

      let(:params) { { cleansheet: [] } }

      it { expect(response).to redirect_to(match_path) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update match_player cleansheet' do
        expect(match_player.reload.cleansheet).to eq(false)
      end
    end
  end
end

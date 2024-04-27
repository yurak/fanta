RSpec.describe 'Users' do
  let(:tournament_round) { create(:tournament_round) }

  describe 'GET #edit' do
    before do
      get edit_tournament_round_path(tournament_round)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get edit_tournament_round_path(tournament_round)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get edit_tournament_round_path(tournament_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:round_players)).not_to be_nil }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get edit_tournament_round_path(tournament_round, club_id: 1)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:round_players)).not_to be_nil }
    end

    context 'with national tournament when admin is logged in' do
      login_admin
      before do
        create_list(:national_team, 4, tournament: tournament_round.tournament)
        get edit_tournament_round_path(tournament_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:round_players)).not_to be_nil }
    end
  end

  describe 'GET #show' do
    before do
      get tournament_round_path(tournament_round)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get tournament_round_path(tournament_round)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get tournament_round_path(tournament_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get tournament_round_path(tournament_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:round_player) { create(:round_player, tournament_round: tournament_round) }
    let(:score) { 7.0 }
    let(:assists_count) { 2 }

    let(:params) do
      {
        round_players: {
          "#{round_player.id}": {
            score: score,
            goals: 1,
            scored_penalty: 1,
            failed_penalty: 1,
            assists: assists_count,
            yellow_card: 1,
            red_card: 1,
            own_goals: 1
          }
        }
      }
    end

    before do
      put tournament_round_path(tournament_round, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        put tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        put tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }

      it 'updates round_player score' do
        expect(round_player.reload.score).to eq(score)
      end

      it 'updates round_player assists' do
        expect(round_player.reload.assists).to eq(assists_count)
      end
    end

    context 'with valid params when admin is logged in' do
      login_admin
      before do
        put tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }

      it 'updates round_player score' do
        expect(round_player.reload.score).to eq(score)
      end

      it 'updates round_player assists' do
        expect(round_player.reload.assists).to eq(assists_count)
      end
    end

    context 'with invalid params when admin is logged in' do
      let(:score) { 'invalid' }

      login_admin
      before do
        put tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update round_player score' do
        expect(round_player.reload.score).not_to eq(score)
      end
    end
  end
end

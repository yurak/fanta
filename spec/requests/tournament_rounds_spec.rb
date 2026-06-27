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

  describe 'GET #stats' do
    before do
      get tournament_round_stats_path(tournament_round)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get tournament_round_stats_path(tournament_round)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get tournament_round_stats_path(tournament_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:stats) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get tournament_round_stats_path(tournament_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:stats) }
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

      it { expect(response).to redirect_to(tournament_round_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        put tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates round_player score' do
        expect(round_player.reload.score).to eq(score)
      end

      it 'updates round_player assists' do
        expect(round_player.reload.assists).to eq(assists_count)
      end

      it 'sets in_squad when score > 0' do
        expect(round_player.reload.in_squad).to be true
      end
    end

    context 'with valid params when admin is logged in' do
      login_admin
      before do
        put tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates round_player score' do
        expect(round_player.reload.score).to eq(score)
      end

      it 'updates round_player assists' do
        expect(round_player.reload.assists).to eq(assists_count)
      end

      it 'sets in_squad when score > 0' do
        expect(round_player.reload.in_squad).to be true
      end
    end

    context 'when admin sets played_minutes > 0 with zero score' do
      login_admin

      let(:params) do
        {
          round_players: {
            "#{round_player.id}": { score: 0, played_minutes: 45, goals: 0, assists: 0,
                                    scored_penalty: 0, failed_penalty: 0, yellow_card: 0,
                                    red_card: 0, own_goals: 0 }
          }
        }
      end

      before { put tournament_round_path(tournament_round, params) }

      it 'sets in_squad' do
        expect(round_player.reload.in_squad).to be true
      end
    end

    context 'when admin submits zero score and zero played_minutes' do
      login_admin

      let(:params) do
        {
          round_players: {
            "#{round_player.id}": { score: 0, played_minutes: 0, goals: 0, assists: 0,
                                    scored_penalty: 0, failed_penalty: 0, yellow_card: 0,
                                    red_card: 0, own_goals: 0 }
          }
        }
      end

      before { put tournament_round_path(tournament_round, params) }

      it 'does not set in_squad' do
        expect(round_player.reload.in_squad).to be false
      end
    end

    context 'with invalid params when admin is logged in' do
      let(:score) { 'invalid' }

      login_admin
      before do
        put tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update round_player score' do
        expect(round_player.reload.score).not_to eq(score)
      end
    end
  end

  describe 'PUT #tours_update' do
    let(:params) do
      {
        status: :set_lineup
      }
    end

    before do
      put tours_update_tournament_round_path(tournament_round, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        put tours_update_tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in without tours' do
      login_moderator
      before do
        put tours_update_tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in with tours' do
      let!(:tours) { create_list(:tour, 3, tournament_round: tournament_round) }

      login_moderator
      before do
        put tours_update_tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates tours status' do
        expect(tournament_round.tours.set_lineup.count).to eq(tours.count)
      end
    end

    context 'when admin is logged in with tours' do
      let!(:tours) { create_list(:tour, 3, tournament_round: tournament_round) }

      login_admin
      before do
        put tours_update_tournament_round_path(tournament_round, params)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates tours status' do
        expect(tournament_round.tours.set_lineup.count).to eq(tours.count)
      end
    end
  end

  describe 'GET #missed_players' do
    before do
      get tournament_round_missed_players_path(tournament_round)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get tournament_round_missed_players_path(tournament_round)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get tournament_round_missed_players_path(tournament_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:missed_players) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get tournament_round_missed_players_path(tournament_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:missed_players) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when the tournament is national and has missed players' do
      let(:national_tournament) { create(:tournament, :with_national_teams) }
      let(:national_round)      { create(:tournament_round, tournament: national_tournament) }
      let(:host)                { national_tournament.national_teams.first }
      let(:guest)               { national_tournament.national_teams.second }

      login_admin
      before do
        create(:national_match, tournament_round: national_round, host_team: host, guest_team: guest,
                                missed_players_data: { '123' => { 'fotmob_id' => 123, 'source_name' => 'Missed Guy',
                                                                  'rating' => '7.5', 'played_minutes' => 90 } })
        get tournament_round_missed_players_path(national_round)
      end

      it { expect(response).to be_successful }
      it { expect(response.body).to include(CGI.escapeHTML("#{host.name} vs #{guest.name}")) }
      it { expect(response.body).to include('Missed Guy') }
    end
  end

  describe 'GET #auto_subs_preview' do
    before do
      get tournament_round_auto_subs_preview_path(tournament_round)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get tournament_round_auto_subs_preview_path(tournament_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:auto_subs_preview) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get tournament_round_auto_subs_preview_path(tournament_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:auto_subs_preview) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'GET #auto_subs' do
    before do
      allow(Substitutes::AutoBot).to receive(:for_round)
      get tournament_round_auto_subs_path(tournament_round)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get tournament_round_auto_subs_path(tournament_round)
      end

      it { expect(response).to redirect_to(tournament_round_auto_subs_preview_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not call AutoBot' do
        expect(Substitutes::AutoBot).not_to have_received(:for_round)
      end
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get tournament_round_auto_subs_path(tournament_round)
      end

      it { expect(response).to redirect_to(tournament_round_auto_subs_preview_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'calls AutoBot' do
        expect(Substitutes::AutoBot).to have_received(:for_round).with(tournament_round, preview: false)
      end
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get tournament_round_auto_subs_path(tournament_round)
      end

      it { expect(response).to redirect_to(tournament_round_auto_subs_preview_path(tournament_round)) }

      it 'calls AutoBot' do
        expect(Substitutes::AutoBot).to have_received(:for_round).with(tournament_round, preview: false)
      end
    end
  end

  describe 'GET #generate_preview' do
    before do
      allow(Substitutes::AutoBot).to receive(:for_round)
      get tournament_round_generate_preview_path(tournament_round)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get tournament_round_generate_preview_path(tournament_round)
      end

      it { expect(response).to redirect_to(tournament_round_auto_subs_preview_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not call AutoBot' do
        expect(Substitutes::AutoBot).not_to have_received(:for_round)
      end
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get tournament_round_generate_preview_path(tournament_round)
      end

      it { expect(response).to redirect_to(tournament_round_auto_subs_preview_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'calls AutoBot in preview mode' do
        expect(Substitutes::AutoBot).to have_received(:for_round).with(tournament_round)
      end
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get tournament_round_generate_preview_path(tournament_round)
      end

      it { expect(response).to redirect_to(tournament_round_auto_subs_preview_path(tournament_round)) }

      it 'calls AutoBot in preview mode' do
        expect(Substitutes::AutoBot).to have_received(:for_round).with(tournament_round)
      end
    end
  end

  describe 'GET #auto_close' do
    before do
      put auto_close_tournament_round_path(tournament_round)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        put auto_close_tournament_round_path(tournament_round)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        put auto_close_tournament_round_path(tournament_round)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates tournament_round moderated time' do
        expect(tournament_round.reload.moderated_at).not_to be_nil
      end
    end

    context 'when admin is logged in' do
      login_admin
      before do
        create_list(:tour, 2, tournament_round: tournament_round)

        put auto_close_tournament_round_path(tournament_round)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates tournament_round moderated time' do
        expect(tournament_round.reload.moderated_at).not_to be_nil
      end
    end
  end
end

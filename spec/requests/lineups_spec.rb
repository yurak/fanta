RSpec.describe 'Lineups', type: :request do
  let(:lineup) { create(:lineup) }

  describe 'GET #new' do
    let(:team) { create(:team, :with_user) }
    let(:tour) { create(:set_lineup_tour) }

    before do
      get new_team_lineup_path(team, tour_id: tour.id)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      login_user
      before do
        get new_team_lineup_path(team, tour_id: tour.id)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when lineup already exist' do
      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user)
        sign_in logged_user
        create(:lineup, tour: tour, team: team)
        get new_team_lineup_path(team, tour_id: tour.id)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when not set_lineup tour' do
      let(:tour) { create(:tour) }

      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user)
        sign_in logged_user
        get new_team_lineup_path(team, tour_id: tour.id)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when user is logged in' do
      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user)
        sign_in logged_user
        get new_team_lineup_path(team, tour_id: tour.id)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:modules)).not_to be_nil }
      it { expect(assigns(:lineup)).not_to be_nil }
    end
  end

  describe 'POST #create' do
    let(:team) { create(:team, :with_user) }
    let(:tour) { create(:set_lineup_tour) }
    let(:params) do
      {
        lineup: { team_module_id: 1, tour_id: tour.id }
      }
    end

    before do
      post team_lineups_path(team, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      login_user
      before do
        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when lineup already exist' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }

      before do
        tour = create(:set_lineup_tour, league: team.league)
        create(:lineup, tour: tour, team: team)
        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and valid params when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }

      before do
        create(:set_lineup_tour, league: team.league)
        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and invalid params when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }
      let(:lineup) { create(:lineup, tour: tour) }

      before do
        allow(Lineup).to receive(:new).and_return(lineup)
        allow(lineup).to receive(:save).and_return(false)

        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(new_team_lineup_path(team, team_module_id: lineup.team_module_id, tour_id: lineup.tour_id)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'GET #edit' do
    before do
      get edit_team_lineup_path(lineup.team, lineup)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team and set_lineup tour when user is logged in' do
      let(:tour) { create(:set_lineup_tour) }
      let(:lineup) { create(:lineup, tour: tour) }

      login_user
      before do
        create(:match, tour: tour, host: lineup.team)
        get edit_team_lineup_path(lineup.team, lineup)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and not set_lineup tour when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:lineup) { create(:lineup, team: create(:team, user: logged_user)) }

      before do
        sign_in logged_user
        create(:match, tour: lineup.tour, host: lineup.team)
        get edit_team_lineup_path(lineup.team, lineup)
      end

      it { expect(response).to redirect_to(tour_path(lineup.tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:lineup) { create(:lineup, team: create(:team, user: logged_user), tour: create(:set_lineup_tour)) }

      before do
        sign_in logged_user
        create(:match, tour: lineup.tour, host: lineup.team)
        get edit_team_lineup_path(lineup.team, lineup)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:lineup)).not_to be_nil }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:logged_user) { create(:user) }

    let(:lineup) do
      create(:lineup, :with_match_players,
             team: create(:team, user: logged_user),
             tour: create(:set_lineup_tour))
    end

    let(:match_players_attributes) do
      {
        '0': { real_position: 'Por', round_player_id: lineup.match_players[0].player.id, id: lineup.match_players[0].id },
        '1': { real_position: 'Dc', round_player_id: lineup.match_players[1].player.id, id: lineup.match_players[1].id },
        '2': { real_position: 'Dc', round_player_id: lineup.match_players[2].player.id, id: lineup.match_players[2].id },
        '3': { real_position: 'Dc', round_player_id: lineup.match_players[3].player.id, id: lineup.match_players[3].id },
        '4': { real_position: 'E', round_player_id: lineup.match_players[4].player.id, id: lineup.match_players[4].id },
        '5': { real_position: 'E', round_player_id: lineup.match_players[5].player.id, id: lineup.match_players[5].id },
        '6': { real_position: 'M/C', round_player_id: lineup.match_players[6].player.id, id: lineup.match_players[6].id },
        '7': { real_position: 'C', round_player_id: lineup.match_players[7].player.id, id: lineup.match_players[7].id },
        '8': { real_position: 'W/A', round_player_id: lineup.match_players[8].player.id, id: lineup.match_players[8].id },
        '9': { real_position: 'W/A', round_player_id: lineup.match_players[9].player.id, id: lineup.match_players[9].id },
        '10': { real_position: 'A/Pc', round_player_id: lineup.match_players[10].player.id, id: lineup.match_players[10].id },
        '11': { round_player_id: lineup.match_players[11].player.id, id: lineup.match_players[11].id },
        '12': { round_player_id: lineup.match_players[12].player.id, id: lineup.match_players[12].id },
        '13': { round_player_id: lineup.match_players[13].player.id, id: lineup.match_players[13].id },
        '14': { round_player_id: lineup.match_players[14].player.id, id: lineup.match_players[14].id },
        '15': { round_player_id: lineup.match_players[15].player.id, id: lineup.match_players[15].id },
        '16': { round_player_id: lineup.match_players[16].player.id, id: lineup.match_players[16].id },
        '17': { round_player_id: lineup.match_players[17].player.id, id: lineup.match_players[17].id }
      }
    end

    let(:params) do
      {
        lineup: {
          match_players_attributes: match_players_attributes
        }
      }
    end

    before do
      put team_lineup_path(lineup.team, lineup, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      login_user
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        put team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(tour_path(lineup.tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and without match_players params when user is logged in' do
      let(:lineup) { create(:lineup, team: create(:team, user: logged_user), tour: create(:set_lineup_tour)) }
      let(:match_players_attributes) { nil }

      before do
        sign_in logged_user
        create(:match, tour: lineup.tour, host: lineup.team)
        put team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(tour_path(lineup.tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and duplicated players when user is logged in' do
      let(:match_players_attributes) do
        {
          '0': { real_position: 'Por', round_player_id: lineup.match_players[0].player.id, id: lineup.match_players[0].id },
          '1': { real_position: 'Dc', round_player_id: lineup.match_players[1].player.id, id: lineup.match_players[1].id },
          '2': { real_position: 'Dc', round_player_id: lineup.match_players[1].player.id, id: lineup.match_players[1].id },
          '3': { real_position: 'Dc', round_player_id: lineup.match_players[3].player.id, id: lineup.match_players[3].id },
          '4': { real_position: 'E', round_player_id: lineup.match_players[4].player.id, id: lineup.match_players[4].id },
          '5': { real_position: 'E', round_player_id: lineup.match_players[5].player.id, id: lineup.match_players[5].id },
          '6': { real_position: 'M/C', round_player_id: lineup.match_players[6].player.id, id: lineup.match_players[6].id },
          '7': { real_position: 'C', round_player_id: lineup.match_players[7].player.id, id: lineup.match_players[7].id },
          '8': { real_position: 'W/A', round_player_id: lineup.match_players[8].player.id, id: lineup.match_players[8].id },
          '9': { real_position: 'W/A', round_player_id: lineup.match_players[9].player.id, id: lineup.match_players[9].id },
          '10': { real_position: 'A/Pc', round_player_id: lineup.match_players[10].player.id, id: lineup.match_players[10].id },
          '11': { round_player_id: lineup.match_players[11].player.id, id: lineup.match_players[11].id },
          '12': { round_player_id: lineup.match_players[12].player.id, id: lineup.match_players[12].id },
          '13': { round_player_id: lineup.match_players[13].player.id, id: lineup.match_players[13].id },
          '14': { round_player_id: lineup.match_players[14].player.id, id: lineup.match_players[14].id },
          '15': { round_player_id: lineup.match_players[15].player.id, id: lineup.match_players[15].id },
          '16': { round_player_id: lineup.match_players[16].player.id, id: lineup.match_players[16].id },
          '17': { round_player_id: lineup.match_players[17].player.id, id: lineup.match_players[17].id }
        }
      end

      before do
        sign_in logged_user
        create(:match, tour: lineup.tour, host: lineup.team)
        put team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(edit_team_lineup_path(lineup.team, lineup)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and valid params when user is logged in' do
      before do
        sign_in logged_user
        create(:match, tour: lineup.tour, host: lineup.team)
        put team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(tour_path(lineup.tour)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'GET #clone' do
    let(:lineup) { create(:lineup, :with_match_players) }
    let(:tour) { create(:tour, league: lineup.tour.league) }

    before do
      get clone_team_lineups_path(lineup.team, tour_id: tour.id)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      login_user
      before do
        get clone_team_lineups_path(lineup.team, tour_id: tour.id)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
      it { expect(tour.lineups).to eq([]) }
    end

    context 'with self team without previous lineup when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:tour) { create(:tour) }
      let(:team) { create(:team, user: logged_user, league: tour.league) }

      before do
        sign_in logged_user
        get clone_team_lineups_path(team, tour_id: tour.id)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
      it { expect(tour.lineups).to eq([]) }
    end

    context 'with self team with already existed lineup for tour when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:tour) { create(:tour) }
      let(:team) { create(:team, user: logged_user, league: tour.league) }
      let(:lineup) { create(:lineup, :with_match_players, team: team, tour: tour) }

      before do
        sign_in logged_user
        get clone_team_lineups_path(team, tour_id: tour.id)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
      it { expect(tour.lineups).to eq([lineup]) }
    end

    context 'with self team without existed lineup for tour when user is logged in' do
      let(:logged_user) { create(:user, team_ids: lineup.team.id) }

      before do
        sign_in logged_user
        get clone_team_lineups_path(lineup.team, tour_id: tour.id)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
      it { expect(tour.lineups.count).to eq(1) }

      it 'calls Cloner service' do
        cloner = instance_double(TeamLineups::Cloner)
        allow(TeamLineups::Cloner).to receive(:new).and_return(cloner)
        allow(cloner).to receive(:call).and_return('lineup')

        get clone_team_lineups_path(lineup.team, tour_id: tour.id)
      end
    end
  end

  describe 'GET #substitutions' do
    let(:lineup) { create(:lineup, :with_match_players) }
    let(:match_player) { lineup.match_players.first }

    before do
      get substitutions_team_lineup_path(lineup.team, lineup, mp: match_player)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_user
      before do
        allow(MatchPlayer).to receive(:find).and_return(match_player)
        allow(match_player).to receive(:not_played?).and_return(true)
        create(:match, tour: lineup.tour, host: lineup.team)
        get substitutions_team_lineup_path(lineup.team, lineup, mp: match_player)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_moderator
      before do
        allow(MatchPlayer).to receive(:find).and_return(match_player)
        allow(match_player).to receive(:not_played?).and_return(true)
        create(:match, tour: lineup.tour, host: lineup.team)
        get substitutions_team_lineup_path(lineup.team, lineup, mp: match_player)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:substitutions) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:lineup)).not_to be_nil }
    end

    context 'when admin is logged in' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:postponed_tour)) }

      login_admin
      before do
        allow(MatchPlayer).to receive(:find).and_return(match_player)
        allow(match_player).to receive(:not_played?).and_return(true)
        create(:match, tour: lineup.tour, host: lineup.team)
        get substitutions_team_lineup_path(lineup.team, lineup, mp: match_player)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:substitutions) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:lineup)).not_to be_nil }
    end

    context 'when admin is logged in with not available tour status' do
      let(:lineup) { create(:lineup, :with_match_players) }

      login_admin
      before do
        allow(MatchPlayer).to receive(:find).and_return(match_player)
        allow(match_player).to receive(:not_played?).and_return(true)
        create(:match, tour: lineup.tour, host: lineup.team)
        get substitutions_team_lineup_path(lineup.team, lineup, mp: match_player)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when admin is logged in and match_player did not play yet' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_admin
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        get substitutions_team_lineup_path(lineup.team, lineup, mp: match_player)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'PUT #subs_update' do
    let(:params) do
      {
        out_mp_id: 1,
        in_mp_id: 2
      }
    end

    before do
      put subs_update_team_lineup_path(lineup.team, lineup, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      let(:lineup) { create(:lineup, :with_match_players, tour: create(:locked_tour)) }

      login_user
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        put subs_update_team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(substitutions_team_lineup_path(lineup.team, lineup)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      let(:lineup) { create(:lineup, tour: create(:locked_tour)) }
      let(:mp_reserve) { create(:match_player, round_player: create(:round_player, :with_pos_dc)) }
      let(:mp_main) { create(:dc_match_player) }

      let(:params) do
        {
          out_mp_id: mp_main.id,
          in_mp_id: mp_reserve.id
        }
      end

      login_moderator
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        put subs_update_team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when admin is logged in' do
      let(:lineup) { create(:lineup, tour: create(:locked_tour)) }
      let(:mp_reserve) { create(:match_player, round_player: create(:round_player, :with_pos_dc)) }
      let(:mp_main) { create(:dc_match_player) }

      let(:params) do
        {
          out_mp_id: mp_main.id,
          in_mp_id: mp_reserve.id
        }
      end

      login_admin
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        put subs_update_team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(match_path(lineup.match)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with incompatible positions when admin is logged in' do
      let(:lineup) { create(:lineup, tour: create(:locked_tour)) }
      let(:mp_reserve) { create(:match_player, round_player: create(:round_player, :with_pos_dc)) }
      let(:mp_main) { create(:w_match_player) }

      let(:params) do
        {
          out_mp_id: mp_main.id,
          in_mp_id: mp_reserve.id
        }
      end

      login_admin
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        put subs_update_team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(substitutions_team_lineup_path(lineup.team, lineup)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with invalid in_mp_id when admin is logged in' do
      let(:lineup) { create(:lineup, tour: create(:locked_tour)) }
      let(:mp_reserve) { create(:match_player, round_player: create(:round_player, :with_pos_dc)) }
      let(:mp_main) { create(:dc_match_player) }

      let(:params) do
        {
          out_mp_id: mp_main.id,
          in_mp_id: 'invalid'
        }
      end

      login_admin
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        put subs_update_team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(substitutions_team_lineup_path(lineup.team, lineup)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with invalid out_mp_id when admin is logged in' do
      let(:lineup) { create(:lineup, tour: create(:locked_tour)) }
      let(:mp_reserve) { create(:match_player, round_player: create(:round_player, :with_pos_dc)) }
      let(:mp_main) { create(:dc_match_player) }

      let(:params) do
        {
          out_mp_id: 'invalid',
          in_mp_id: mp_reserve.id
        }
      end

      login_admin
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        put subs_update_team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(substitutions_team_lineup_path(lineup.team, lineup)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'without params when admin is logged in' do
      let(:lineup) { create(:lineup, tour: create(:locked_tour)) }

      let(:params) { '' }

      login_admin
      before do
        create(:match, tour: lineup.tour, host: lineup.team)
        put subs_update_team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(substitutions_team_lineup_path(lineup.team, lineup)) }
      it { expect(response).to have_http_status(:found) }
    end
  end
end

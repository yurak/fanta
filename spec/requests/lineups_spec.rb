RSpec.describe 'Lineups', type: :request do
  let(:lineup) { create(:lineup) }

  describe 'GET #show' do
    context 'when user is logged out and tour is not deadlined' do
      let(:tour) { create(:set_lineup_tour) }
      let(:team) { create(:team, :with_user) }
      let(:lineup) { create(:lineup, tour: tour, team: team) }

      before do
        get team_lineup_path(team, lineup)
      end

      it { expect(response).to redirect_to(tour_path(lineup.tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged out and tour is not deadlined' do
      let(:team) { create(:team, :with_user) }

      login_user
      before do
        get team_lineup_path(team, lineup)
      end

      it { expect(response).to redirect_to(tour_path(lineup.tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when user is logged in' do
      let(:tour) { create(:set_lineup_tour) }

      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user)
        sign_in logged_user
        lineup = create(:lineup, tour: tour, team: team)

        get team_lineup_path(team, lineup)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:lineup)).not_to be_nil }
    end

    context 'when user is logged out and tour is deadlined' do
      let(:tour) { create(:locked_tour) }
      let(:team) { create(:team, :with_user) }
      let(:lineup) { create(:lineup, tour: tour, team: team) }

      before do
        get team_lineup_path(team, lineup)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:lineup)).not_to be_nil }
      it { expect(assigns(:lineup)).to eq(lineup) }
    end
  end

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

    context 'when national tour and duplicated players and user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }
      let!(:tour) { create(:set_lineup_tour, league: team.league) }

      before do
        create(:national_match, tournament_round: tour.tournament_round)
        round_player1 = create(:round_player, player: create(:player, :with_national_team))
        params = {
          lineup: {
            team_module_id: 1, tour_id: tour.id, match_players_attributes: {
              '0' => { round_player_id: round_player1.id },
              '1' => { round_player_id: round_player1.id }
            }
          }
        }

        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(new_team_lineup_path(team, team_module_id: lineup.team_module_id, tour_id: tour.id)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when national tour and not enough national teams used and user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }
      let!(:tour) { create(:set_lineup_tour, league: team.league) }

      before do
        create(:national_match, tournament_round: tour.tournament_round)
        round_player1 = create(:round_player, player: create(:player, :with_national_team))
        params = {
          lineup: {
            team_module_id: 1, tour_id: tour.id, match_players_attributes: {
              '0' => { round_player_id: round_player1.id }
            }
          }
        }

        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(new_team_lineup_path(team, team_module_id: lineup.team_module_id, tour_id: tour.id)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when national tour and used too much players from one team and user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }
      let!(:tour) { create(:set_lineup_tour, league: team.league) }

      before do
        create(:national_match, tournament_round: tour.tournament_round)
        rp = create(:round_player, player: create(:player, :with_national_team))
        params = {
          lineup: {
            team_module_id: 1, tour_id: tour.id, match_players_attributes: {
              '0' => { round_player_id: create(:round_player, player: create(:player, :with_national_team)).id },
              '1' => { round_player_id: rp.id },
              '2' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).id },
              '3' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).id },
              '4' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).id },
              '5' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).id },
              '6' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).id },
              '7' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).id },
              '8' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).id },
              '9' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).id },
              '10' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).id }
            }
          }
        }

        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(new_team_lineup_path(team, team_module_id: lineup.team_module_id, tour_id: tour.id)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when national tour and valid match_players and user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }
      let!(:tour) { create(:set_lineup_tour, league: team.league) }

      before do
        create(:national_match, tournament_round: tour.tournament_round)
        round_player1 = create(:round_player, player: create(:player, :with_national_team))
        round_player2 = create(:round_player, player: create(:player, :with_national_team))
        params = {
          lineup: {
            team_module_id: 1, tour_id: tour.id, match_players_attributes: {
              '0' => { round_player_id: round_player1.id },
              '1' => { round_player_id: round_player2.id }
            }
          }
        }

        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
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

    context 'with self team in unclonable league without existed lineup for tour when user is logged in' do
      let(:logged_user) { create(:user, team_ids: lineup.team.id) }

      before do
        sign_in logged_user
        get clone_team_lineups_path(lineup.team, tour_id: tour.id)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
      it { expect(tour.lineups).to eq([]) }
    end

    context 'with self team in cloneable league without existed lineup for tour when user is logged in' do
      let(:logged_user) { create(:user, team_ids: lineup.team.id) }

      before do
        lineup.team.league.cloneable!
        sign_in logged_user
        get clone_team_lineups_path(lineup.team, tour_id: tour.id)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
      it { expect(tour.lineups.count).to eq(1) }

      it 'calls Cloner service' do
        cloner = instance_double(Lineups::Cloner)
        allow(Lineups::Cloner).to receive(:new).and_return(cloner)
        allow(cloner).to receive(:call).and_return('lineup')

        get clone_team_lineups_path(lineup.team, tour_id: tour.id)
      end
    end
  end
end

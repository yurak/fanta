RSpec.describe 'Lineups' do
  let(:lineup) { create(:lineup) }

  def squad_attrs(count)
    create_list(:player, count).each_with_index.to_h { |player, i| [i.to_s, { round_player_id: player.id }] }
  end

  def players_attrs(players)
    players.each_with_index.to_h { |player, i| [i.to_s, { round_player_id: player.id }] }
  end

  def fanta_set_lineup_tour(**attrs)
    create(:set_lineup_tour, tournament_round: create(:tournament_round, tournament: create(:fanta_tournament)), **attrs)
  end

  describe 'GET #show' do
    context 'when user is logged out' do
      let(:tour) { create(:set_lineup_tour) }
      let(:team) { create(:team, :with_user) }
      let(:lineup) { create(:lineup, tour: tour, team: team) }

      before do
        get team_lineup_path(team, lineup)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in and tour is not deadlined' do
      let(:team) { create(:team, :with_user) }

      login_user
      before do
        get team_lineup_path(team, lineup)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:lineup)).not_to be_nil }
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
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:lineup)).not_to be_nil }
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
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:modules)).not_to be_nil }
      it { expect(assigns(:lineup)).not_to be_nil }
    end
  end

  describe 'POST #create' do
    let(:team) { create(:team, :with_user) }
    let(:tour) { create(:set_lineup_tour) }
    let!(:team_module) { TeamModule.first || create(:team_module) }
    let(:params) do
      {
        lineup: { team_module_id: team_module.id, tour_id: tour.id }
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
        create(:lineup, tour: tour, team: team)
        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and a full valid mantra squad when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, :with_20_players, user: logged_user) }
      let(:params) do
        { lineup: { team_module_id: team_module.id, tour_id: tour.id, match_players_attributes: players_attrs(team.players) } }
      end

      before do
        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when a mantra player is not in the team' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, :with_20_players, user: logged_user) }
      let(:params) do
        attrs = players_attrs(team.players)
        attrs['19'] = { round_player_id: create(:player).id }
        { lineup: { team_module_id: team_module.id, tour_id: tour.id, match_players_attributes: attrs } }
      end

      before do
        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it 'does not create a lineup' do
        expect(Lineup.count).to eq(0)
      end
    end

    context 'with own team and an incomplete mantra squad when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }
      let(:params) do
        { lineup: { team_module_id: team_module.id, tour_id: tour.id, match_players_attributes: squad_attrs(11) } }
      end

      before do
        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it 'bounces back to the form without creating a lineup' do
        expect(response).to redirect_to(new_team_lineup_path(team, team_module_id: team_module.id, tour_id: tour.id))
      end

      it 'does not create a lineup' do
        expect(Lineup.count).to eq(0)
      end

      it 'shows the validation message on the form' do
        follow_redirect!
        expect(response.body).to include(I18n.t('lineups.invalid_squad'))
      end
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
            team_module_id: team_module.id, tour_id: tour.id, match_players_attributes: {
              '0' => { round_player_id: round_player1.player_id },
              '1' => { round_player_id: round_player1.player_id }
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
            team_module_id: team_module.id, tour_id: tour.id, match_players_attributes: {
              '0' => { round_player_id: round_player1.player_id }
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
            team_module_id: team_module.id, tour_id: tour.id, match_players_attributes: {
              '0' => { round_player_id: create(:round_player, player: create(:player, :with_national_team)).player_id },
              '1' => { round_player_id: rp.player_id },
              '2' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).player_id },
              '3' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).player_id },
              '4' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).player_id },
              '5' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).player_id },
              '6' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).player_id },
              '7' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).player_id },
              '8' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).player_id },
              '9' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).player_id },
              '10' => { round_player_id: create(:round_player, player: create(:player, national_team: rp.player.national_team)).player_id }
            }
          }
        }

        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(new_team_lineup_path(team, team_module_id: lineup.team_module_id, tour_id: tour.id)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when national tour and a full valid squad and user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }
      let!(:tour) { fanta_set_lineup_tour(league: team.league) }
      let(:players) do
        create_list(:player, 8, national_team: create(:national_team)) +
          create_list(:player, 8, national_team: create(:national_team))
      end
      let(:params) do
        { lineup: { team_module_id: team_module.id, tour_id: tour.id, match_players_attributes: players_attrs(players) } }
      end

      before do
        national_teams = players.map(&:national_team).uniq
        create(:national_match, tournament_round: tour.tournament_round,
                                host_team: national_teams.first, guest_team: national_teams.second)
        sign_in logged_user

        post team_lineups_path(team, params)
      end

      it { expect(response).to redirect_to(team_lineup_path(team, Lineup.last)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when a fanta player is not in the round clubs' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }
      let!(:tour) { fanta_set_lineup_tour(league: team.league) }

      before do
        club_one = create(:club)
        club_two = create(:club)
        create(:tournament_match, tournament_round: tour.tournament_round, host_club: club_one, guest_club: club_two)
        outsider = create(:player, club: create(:club))
        players = create_list(:player, 8, club: club_one) + create_list(:player, 7, club: club_two) + [outsider]
        sign_in logged_user

        post team_lineups_path(team, lineup: { team_module_id: team_module.id, tour_id: tour.id,
                                               match_players_attributes: players_attrs(players) })
      end

      it 'does not create a lineup' do
        expect(Lineup.count).to eq(0)
      end
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

      it { expect(response).to redirect_to(edit_team_lineup_path(lineup.team, lineup)) }
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

    context 'with own team and a full valid squad when user is logged in' do
      let(:team) { create(:team, :with_20_players, user: logged_user) }
      let(:lineup) { create(:lineup, team: team, tour: create(:set_lineup_tour)) }
      let(:match_players_attributes) { players_attrs(team.players) }

      before do
        sign_in logged_user
        create(:match, tour: lineup.tour, host: lineup.team)
        put team_lineup_path(lineup.team, lineup, params)
      end

      it { expect(response).to redirect_to(tour_path(lineup.tour)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe 'POST #fanta_copy' do
    let(:user) { create(:user) }
    let(:tournament) { create(:fanta_tournament) }
    let(:tournament_round) { create(:tournament_round, tournament: tournament) }
    let(:source_league) { create(:active_league, tournament: tournament) }
    let(:target_league) { create(:active_league, tournament: tournament) }
    let(:source_team) { create(:team, user: user, league: source_league) }
    let(:target_team) { create(:team, user: user, league: target_league) }
    let(:source_tour) { create(:set_lineup_tour, league: source_league, tournament_round: tournament_round) }
    let(:target_tour) { create(:set_lineup_tour, league: target_league, tournament_round: tournament_round) }
    let(:fanta_lineup) { create(:lineup, :with_fanta_score_five, team: source_team, tour: source_tour) }

    before { fanta_lineup && target_team && target_tour }

    context 'when user is logged out' do
      before { post fanta_copy_team_lineup_path(source_team, fanta_lineup) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when user is logged in as team owner' do
      before do
        sign_in user
        post fanta_copy_team_lineup_path(source_team, fanta_lineup)
      end

      it { expect(response).to redirect_to(team_lineup_path(source_team, fanta_lineup)) }
      it { expect(response).to have_http_status(:found) }

      it 'copies lineup to other fanta leagues' do
        expect(target_tour.lineups.count).to eq(1)
      end
    end

    context 'when user is logged in as foreign user' do
      before do
        sign_in create(:user)
        post fanta_copy_team_lineup_path(source_team, fanta_lineup)
      end

      it 'does not copy lineup' do
        expect(target_tour.lineups.count).to eq(0)
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

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
        cloner = instance_double(Lineups::Cloner)
        allow(Lineups::Cloner).to receive(:new).and_return(cloner)
        allow(cloner).to receive(:call).and_return('lineup')

        get clone_team_lineups_path(lineup.team, tour_id: tour.id)

        expect(response).to redirect_to(tour_path(tour))
      end
    end
  end
end

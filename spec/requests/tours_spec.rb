RSpec.describe 'Tours' do
  let(:tour) { create(:tour) }

  describe 'GET #show' do
    context 'when user is logged out' do
      before do
        get tour_path(tour)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with valid tour' do
      login_user
      before do
        get tour_path(tour)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:results_ordered)).not_to be_nil }
      it { expect(assigns(:results_by_score)).not_to be_nil }
      it { expect(assigns(:matches)).not_to be_nil }
    end

    context 'with invalid tour id' do
      login_user
      before do
        get tour_path('tour_random_id')
      end

      it { expect(response).not_to be_successful }
      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
      it { expect(assigns(:results_ordered)).to be_nil }
      it { expect(assigns(:results_by_score)).to be_nil }
      it { expect(assigns(:matches)).to be_nil }
    end
  end

  describe 'GET #show clone button visibility' do
    let(:league) { create(:league) }
    let(:set_lineup_tour) { create(:set_lineup_tour, league: league) }

    login_user

    context 'when user has a previous lineup in the same league' do
      before do
        team = create(:team, user: User.last, league: league)
        old_tour = create(:tour, league: league)
        create(:lineup, team: team, tour: old_tour)
        get tour_path(set_lineup_tour)
      end

      it 'shows the clone button' do
        expect(response.body).to include(clone_team_lineups_path(Team.last, tour_id: set_lineup_tour.id))
      end
    end

    context 'when it is the first tour with no previous lineup' do
      before do
        create(:team, user: User.last, league: league)
        get tour_path(set_lineup_tour)
      end

      it 'does not show the clone button' do
        expect(response.body).not_to include('clone_team_lineups')
      end
    end

    context 'when user has lineups only in another league' do
      before do
        create(:team, user: User.last, league: league)
        other_league = create(:league)
        create(:team, user: User.last, league: other_league).tap do |other_team|
          create(:lineup, team: other_team, tour: create(:tour, league: other_league))
        end
        get tour_path(set_lineup_tour)
      end

      it 'does not show the clone button' do
        expect(response.body).not_to include(clone_team_lineups_path(Team.first, tour_id: set_lineup_tour.id))
      end
    end
  end

  describe 'GET #show fanta tour with national matches' do
    let(:fanta_league) { create(:league, :fanta_league) }
    let(:fanta_round) { create(:tournament_round, tournament: fanta_league.tournament) }
    let(:fanta_tour) { create(:tour, league: fanta_league, tournament_round: fanta_round) }

    login_user

    context 'when national match has time and date' do
      before do
        create(:national_match, tournament_round: fanta_round, time: '20:00', date: 'JUN 15, 2026')
        get tour_path(fanta_tour)
      end

      it { expect(response).to be_successful }
      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template(:show) }
    end

    context 'when national match has no time' do
      before do
        create(:national_match, tournament_round: fanta_round, time: '', date: '')
        get tour_path(fanta_tour)
      end

      it { expect(response).to be_successful }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'GET #tournament_players' do
    context 'when user is logged out' do
      before do
        get tournament_players_tour_path(tour)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with valid tour' do
      login_user
      before do
        get tournament_players_tour_path(tour)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template('tours/_tournament_players') }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:tournament_players)).not_to be_nil }
      it { expect(assigns(:teams_by_player)).not_to be_nil }
    end

    context 'with invalid tour id' do
      login_user
      before do
        get tournament_players_tour_path('tour_random_id')
      end

      it { expect(response).not_to be_successful }
      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
      it { expect(assigns(:tournament_players)).to be_nil }
      it { expect(assigns(:teams_by_player)).to be_nil }
    end

    context 'with player data' do
      login_user

      let(:t_round) { tour.tournament_round }
      let!(:rp_high) { create(:round_player, tournament_round: t_round, score: 9, final_score: 9) }
      let!(:rp_low)  { create(:round_player, tournament_round: t_round, score: 7, final_score: 7) }
      let!(:rp_zero) { create(:round_player, tournament_round: t_round, score: 0) }

      before { get tournament_players_tour_path(tour) }

      it 'includes players with score > 0' do
        expect(assigns(:tournament_players)).to include(rp_high, rp_low)
      end

      it 'excludes players with score = 0' do
        expect(assigns(:tournament_players)).not_to include(rp_zero)
      end

      it 'sorts by result_score descending' do
        expect(assigns(:tournament_players).first).to eq(rp_high)
      end

      context 'when more than 5 players have scores' do
        before do
          create_list(:round_player, 4, tournament_round: t_round, score: 6, final_score: 6)
          get tournament_players_tour_path(tour)
        end

        it 'limits to 5 players' do
          expect(assigns(:tournament_players).size).to eq(5)
        end
      end

      context 'when player belongs to a team in the tour league' do
        let(:team) { create(:team, league: tour.league, players: [rp_high.player]) }

        before do
          team
          get tournament_players_tour_path(tour)
        end

        it 'maps player to the correct team in @teams_by_player' do
          expect(assigns(:teams_by_player)[rp_high.id]).to eq(team)
        end
      end
    end
  end

  describe 'GET #league_players' do
    context 'when user is logged out' do
      before do
        get league_players_tour_path(tour)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with valid tour' do
      login_user
      before do
        get league_players_tour_path(tour)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template('tours/_league_players') }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:league_players)).not_to be_nil }
      it { expect(assigns(:teams_by_player)).not_to be_nil }
    end

    context 'with invalid tour id' do
      login_user
      before do
        get league_players_tour_path('tour_random_id')
      end

      it { expect(response).not_to be_successful }
      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
      it { expect(assigns(:league_players)).to be_nil }
      it { expect(assigns(:teams_by_player)).to be_nil }
    end

    context 'with player data' do
      login_user

      let(:lineup) { create(:lineup, tour: tour) }
      let!(:mp_with_score) do
        create(:match_player, lineup: lineup, real_position: 'A',
                              round_player: create(:round_player, tournament_round: tour.tournament_round, score: 8, final_score: 8))
      end
      let!(:mp_higher_score) do
        create(:match_player, lineup: lineup, real_position: 'A',
                              round_player: create(:round_player, tournament_round: tour.tournament_round, score: 9, final_score: 9))
      end
      let!(:mp_no_score) do
        create(:match_player, lineup: lineup, real_position: 'A',
                              round_player: create(:round_player, tournament_round: tour.tournament_round, score: 0))
      end
      let!(:mp_no_position) do
        create(:match_player, lineup: lineup, real_position: nil,
                              round_player: create(:round_player, tournament_round: tour.tournament_round, score: 7, final_score: 7))
      end

      before { get league_players_tour_path(tour) }

      it 'includes main players with score > 0' do
        expect(assigns(:league_players)).to include(mp_with_score, mp_higher_score)
      end

      it 'excludes players with score = 0' do
        expect(assigns(:league_players)).not_to include(mp_no_score)
      end

      it 'excludes players without real_position (non-main)' do
        expect(assigns(:league_players)).not_to include(mp_no_position)
      end

      it 'sorts by total_score descending' do
        expect(assigns(:league_players).first).to eq(mp_higher_score)
      end

      context 'when more than 5 players qualify' do
        before do
          t_round = tour.tournament_round
          create_list(:match_player, 4, lineup: lineup, real_position: 'A',
                                        round_player: create(:round_player, tournament_round: t_round,
                                                                            score: 6, final_score: 6))
          get league_players_tour_path(tour)
        end

        it 'limits to 5 players' do
          expect(assigns(:league_players).size).to eq(5)
        end
      end

      context 'when player belongs to a team in the tour league' do
        let(:team) { create(:team, league: tour.league, players: [mp_with_score.player]) }

        before do
          team
          get league_players_tour_path(tour)
        end

        it 'maps match_player to the correct team in @teams_by_player' do
          expect(assigns(:teams_by_player)[mp_with_score.id]).to eq(team)
        end
      end
    end
  end

  describe 'PUT/PATCH #update' do
    let(:status) { 'set_lineup' }
    let(:params) { { status: status } }

    before do
      put tour_path(tour, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        put tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update tour with specified status' do
        expect(tour.reload.status).not_to eq(status)
      end
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        put tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'does not update tour with specified status' do
        expect(tour.reload.status).not_to eq(status)
      end
    end

    context 'with valid tour status when admin is logged in' do
      login_admin
      before do
        put tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates tour with specified status' do
        expect(tour.reload.status).to eq(status)
      end

      it 'calls Tours::Manager service' do
        manager = instance_double(Tours::Manager)
        allow(Tours::Manager).to receive(:new).and_return(manager)
        allow(manager).to receive(:call).and_return(tour)

        put tour_path(tour, params)

        expect(manager).to have_received(:call)
      end
    end

    context 'with not valid tour status when admin is logged in' do
      let(:status) { 'closed' }

      login_admin
      before do
        put tour_path(tour, params)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'calls Tours::Manager service' do
        manager = instance_double(Tours::Manager)
        allow(Tours::Manager).to receive(:new).and_return(manager)
        allow(manager).to receive(:call).and_return(tour)

        put tour_path(tour, params)

        expect(manager).to have_received(:call)
      end

      it 'does not update tour with specified status' do
        expect(tour.reload.status).not_to eq(status)
      end
    end
  end

  describe 'GET #inject_scores' do
    before do
      get inject_scores_tour_path(tour)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get inject_scores_tour_path(tour)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator

      before do
        allow(Scores::PositionMalus::Updater).to receive(:call)
        allow(Lineups::Updater).to receive(:call)
        allow_any_instance_of(Scores::Injectors::Fotmob).to receive(:call)
        get inject_scores_tour_path(tour)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'calls PositionMalus::Updater' do
        expect(Scores::PositionMalus::Updater).to have_received(:call)
      end

      it 'calls Lineups::Updater' do
        expect(Lineups::Updater).to have_received(:call)
      end

      it 'calls injector' do
        allow(Scores::PositionMalus::Updater).to receive(:call)
        allow(Lineups::Updater).to receive(:call)
        expect_any_instance_of(Scores::Injectors::Fotmob).to receive(:call)
        get inject_scores_tour_path(tour)
      end

      it 'redirects to tournament_round when redirect=round param is given' do
        allow_any_instance_of(Scores::Injectors::Fotmob).to receive(:call)
        get inject_scores_tour_path(tour, redirect: 'round')

        expect(response).to redirect_to(tournament_round_path(tour.tournament_round))
      end
    end

    context 'when admin is logged in' do
      login_admin

      before do
        allow(Scores::PositionMalus::Updater).to receive(:call)
        allow(Lineups::Updater).to receive(:call)
        allow_any_instance_of(Scores::Injectors::Fotmob).to receive(:call)
        get inject_scores_tour_path(tour)
      end

      it { expect(response).to redirect_to(tour_path(tour)) }
      it { expect(response).to have_http_status(:found) }

      it 'calls injector' do
        allow(Scores::PositionMalus::Updater).to receive(:call)
        allow(Lineups::Updater).to receive(:call)
        expect_any_instance_of(Scores::Injectors::Fotmob).to receive(:call)
        get inject_scores_tour_path(tour)
      end

      it 'calls PositionMalus::Updater' do
        expect(Scores::PositionMalus::Updater).to have_received(:call)
      end

      it 'calls Lineups::Updater' do
        expect(Lineups::Updater).to have_received(:call)
      end
    end
  end

  describe 'GET #show fanta tour lineups ordering with equal scores' do
    let(:fanta_league) { create(:league, :fanta_league) }
    let(:fanta_tour) do
      create(:closed_tour, league: fanta_league,
                           tournament_round: create(:tournament_round, tournament: fanta_league.tournament))
    end
    let!(:lineup_one) { create(:lineup, :with_fanta_score_five, tour: fanta_tour, final_score: 55) }
    let!(:lineup_two) { create(:lineup, :with_fanta_score_five, tour: fanta_tour, final_score: 55) }

    login_user

    # Equal final_score: lineup_two wins on the best-main-score tiebreaker, so it
    # must appear above lineup_one — matching the saved lineup.position (ordered_lineups).
    before do
      lineup_two.match_players.main.last.round_player.update(score: 9.0)
      get tour_path(fanta_tour)
    end

    it 'orders teams by tiebreaker, not by score alone' do
      expect(response.body.index(lineup_two.team.human_name))
        .to be < response.body.index(lineup_one.team.human_name)
    end
  end
end

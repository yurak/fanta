RSpec.describe 'Manage::Leagues' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_leagues_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_leagues_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      let!(:initial_league) { create(:league) }
      let!(:active_league) { create(:active_league) }

      before do
        create(:archived_league)
        get manage_leagues_path
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'defaults to initial tab' do
        expect(controller.instance_variable_get(:@status)).to eq('initial')
      end

      it 'shows only initial leagues by default' do
        expect(controller.instance_variable_get(:@leagues)).to include(initial_league)
      end

      it 'excludes non-initial leagues by default' do
        expect(controller.instance_variable_get(:@leagues)).not_to include(active_league)
      end
    end

    context 'when admin filters by active status' do
      login_admin

      let!(:initial_league) { create(:league) }
      let!(:active_league) { create(:active_league) }

      before { get manage_leagues_path(status: 'active') }

      it 'shows only active leagues' do
        expect(controller.instance_variable_get(:@leagues)).to include(active_league)
      end

      it 'excludes initial leagues' do
        expect(controller.instance_variable_get(:@leagues)).not_to include(initial_league)
      end
    end

    context 'when admin filters by archived status' do
      login_admin

      let!(:archived_league) { create(:archived_league) }
      let!(:initial_league) { create(:league) }

      before { get manage_leagues_path(status: 'archived') }

      it 'shows only archived leagues' do
        expect(controller.instance_variable_get(:@leagues)).to include(archived_league)
      end

      it 'excludes initial leagues' do
        expect(controller.instance_variable_get(:@leagues)).not_to include(initial_league)
      end
    end

    context 'when admin provides invalid status' do
      login_admin

      before { get manage_leagues_path(status: 'invalid') }

      it 'defaults to initial' do
        expect(controller.instance_variable_get(:@status)).to eq('initial')
      end
    end

    context 'when filtering by name query' do
      login_admin

      let!(:matching_league) { create(:league, name: 'Alpha League') }
      let!(:other_league) { create(:league, name: 'Beta League') }

      before { get manage_leagues_path(query: 'Alpha') }

      it 'includes matching league' do
        expect(controller.instance_variable_get(:@leagues)).to include(matching_league)
      end

      it 'excludes non-matching league' do
        expect(controller.instance_variable_get(:@leagues)).not_to include(other_league)
      end
    end

    context 'when filtering by tournament' do
      login_admin

      let(:tournament_a) { create(:tournament) }
      let(:tournament_b) { create(:tournament) }
      let!(:league_a) { create(:league, tournament: tournament_a) }
      let!(:league_b) { create(:league, tournament: tournament_b) }

      before { get manage_leagues_path(tournament_id: tournament_a.id) }

      it 'includes league from selected tournament' do
        expect(controller.instance_variable_get(:@leagues)).to include(league_a)
      end

      it 'excludes league from other tournament' do
        expect(controller.instance_variable_get(:@leagues)).not_to include(league_b)
      end
    end

    context 'when filtering by season' do
      login_admin

      let!(:season_a) { create(:season) }
      let!(:season_b) { create(:season) }
      let!(:league_a) { create(:league, season: season_a) }
      let!(:league_b) { create(:league, season: season_b) }

      before { get manage_leagues_path(season_id: season_a.id) }

      it 'includes league from selected season' do
        expect(controller.instance_variable_get(:@leagues)).to include(league_a)
      end

      it 'excludes league from other season' do
        expect(controller.instance_variable_get(:@leagues)).not_to include(league_b)
      end
    end

    context 'with pagination' do
      login_admin

      before do
        create_list(:league, Manage::LeaguesController::PER_PAGE + 1)
        get manage_leagues_path
      end

      it 'paginates results' do
        expect(controller.instance_variable_get(:@leagues).count).to eq(Manage::LeaguesController::PER_PAGE)
      end
    end
  end

  describe 'GET #new' do
    context 'when user is logged out' do
      before { get new_manage_league_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get new_manage_league_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      before { get new_manage_league_path }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(controller.instance_variable_get(:@league)).to be_a_new(League) }
    end
  end

  describe 'POST #create' do
    let(:tournament) { Tournament.first }
    let(:season) { Season.last }
    let(:valid_params) do
      { league: { name: 'Test League', tournament_id: tournament.id, season_id: season.id } }
    end
    let(:invalid_params) do
      { league: { name: '', tournament_id: tournament.id, season_id: season.id } }
    end

    context 'when user is logged out' do
      before { post manage_leagues_path, params: valid_params }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { post manage_leagues_path, params: valid_params }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin creates a league with valid params' do
      login_admin

      before { post manage_leagues_path, params: valid_params }

      it { expect(response).to redirect_to(manage_leagues_path) }

      it 'creates a new league' do
        expect(League.find_by(name: 'Test League')).to be_present
      end
    end

    context 'when admin creates a league with invalid params' do
      login_admin

      before { post manage_leagues_path, params: invalid_params }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template(:new) }
    end
  end

  describe 'GET #edit' do
    let!(:league) { create(:league) }

    context 'when user is logged out' do
      before { get edit_manage_league_path(league) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get edit_manage_league_path(league) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      before { get edit_manage_league_path(league) }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
    end
  end

  describe 'PATCH #update' do
    let!(:league) { create(:league) }

    context 'when user is logged out' do
      before { patch manage_league_path(league), params: { league: { name: 'Updated' } } }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { patch manage_league_path(league), params: { league: { name: 'Updated' } } }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin updates with valid params' do
      login_admin

      before { patch manage_league_path(league), params: { league: { name: 'Updated Name' } } }

      it { expect(response).to redirect_to(manage_leagues_path) }

      it 'updates the league' do
        expect(league.reload.name).to eq('Updated Name')
      end
    end

    context 'when admin sets demo flag' do
      login_admin

      before { patch manage_league_path(league), params: { league: { demo: true } } }

      it 'saves the demo flag' do
        expect(league.reload.demo).to be(true)
      end
    end

    context 'when admin updates with invalid params' do
      login_admin

      before { patch manage_league_path(league), params: { league: { name: '' } } }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template(:edit) }
    end
  end

  describe 'GET #show' do
    let!(:league) { create(:active_league) }

    context 'when user is logged out' do
      before { get manage_league_path(league) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_league_path(league) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      let(:team) { create(:team, league: league) }
      let!(:result) { create(:result, league: league, team: team) }

      before { get manage_league_path(league) }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }

      it 'loads results indexed by team_id' do
        results_by_team = controller.instance_variable_get(:@results_by_team)
        expect(results_by_team[team.id]).to eq(result)
      end

      it 'does not include results for other teams' do
        results_by_team = controller.instance_variable_get(:@results_by_team)
        expect(results_by_team.keys).to contain_exactly(team.id)
      end
    end
  end

  describe 'POST #crown' do
    let(:champion_user) { create(:user) }
    let(:league) { create(:archived_league) }
    let(:team) { create(:team, league: league, user: champion_user) }
    let!(:result) { create(:result, league: league, team: team, points: 50) }

    before { create(:result, league: league, points: 20) }

    context 'when user is logged out' do
      before { post crown_manage_league_path(league, result_id: result.id) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { post crown_manage_league_path(league, result_id: result.id) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      context 'with a valid result' do
        before { post crown_manage_league_path(league, result_id: result.id) }

        it { expect(response).to redirect_to(manage_league_path(league)) }

        it 'sets result title to true' do
          expect(result.reload.title).to be(true)
        end

        it 'creates a UserTitle for the result' do
          expect(UserTitle.find_by(result: result)).to be_present
        end

        it 'sets the correct season on UserTitle' do
          title = UserTitle.find_by(result: result)
          expect(title.season).to eq("#{league.season.start_year}/#{league.season.end_year}")
        end

        it 'sets championship_number to 1 for first title' do
          expect(UserTitle.find_by(result: result).championship_number).to eq(1)
        end

        it 'assigns champion_number to user' do
          expect(champion_user.reload.champion_number).to be_present
        end
      end

      context 'when user already has a champion_number' do
        before { champion_user.update!(champion_number: 5) }

        it 'does not overwrite existing champion_number' do
          post crown_manage_league_path(league, result_id: result.id)
          expect(champion_user.reload.champion_number).to eq(5)
        end
      end

      context 'when other titles already exist globally' do
        before { create(:user_title, championship_number: 3) }

        it 'assigns next global championship_number' do
          post crown_manage_league_path(league, result_id: result.id)
          expect(UserTitle.find_by(result: result).championship_number).to eq(4)
        end
      end

      context 'when another user already has champion_number' do
        before { create(:user, champion_number: 3) }

        it 'assigns the next available champion_number' do
          post crown_manage_league_path(league, result_id: result.id)
          expect(champion_user.reload.champion_number).to eq(4)
        end
      end
    end
  end

  describe 'POST #activate' do
    let!(:league) { create(:league, :with_five_teams) }
    let(:deadline) { 1.week.from_now.strftime('%Y-%m-%dT%H:%M') }

    before do
      create(:tournament_round, number: 1, tournament: league.tournament, season: league.season)
    end

    context 'when user is logged out' do
      before { post activate_manage_league_path(league, deadline: deadline) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { post activate_manage_league_path(league, deadline: deadline) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin activates a league' do
      login_admin

      before { post activate_manage_league_path(league, deadline: deadline) }

      it { expect(response).to redirect_to(manage_leagues_path) }

      it 'activates the league' do
        expect(league.reload).to be_active
      end

      it 'creates the first auction round' do
        expect(league.auctions.find_by(number: 1).auction_rounds.count).to eq(1)
      end

      it 'sets the first auction to blind_bids' do
        expect(league.auctions.find_by(number: 1)).to be_blind_bids
      end

      it 'creates auction bids for all teams' do
        auction_round = league.auctions.find_by(number: 1).auction_rounds.first
        expect(auction_round.auction_bids.count).to eq(league.teams.count)
      end
    end

    context 'when a team has an existing bid without a round' do
      login_admin

      let(:team_with_bid) { league.teams.first }
      let!(:existing_bid) { create(:auction_bid, team: team_with_bid, auction_round: nil) }

      before { post activate_manage_league_path(league, deadline: deadline) }

      it 'links the existing bid to the first auction round' do
        auction_round = league.auctions.find_by(number: 1).auction_rounds.first
        expect(existing_bid.reload.auction_round).to eq(auction_round)
      end

      it 'does not create a duplicate bid for that team' do
        auction_round = league.auctions.find_by(number: 1).auction_rounds.first
        expect(auction_round.auction_bids.where(team: team_with_bid).count).to eq(1)
      end
    end
  end
end

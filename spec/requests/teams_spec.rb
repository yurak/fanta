RSpec.describe 'Teams' do
  let(:team) { create(:team) }

  describe 'GET #show' do
    let(:team) { create(:team, :with_league_matches) }

    context 'when user is logged out' do
      before do
        get team_path(team)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get team_path(team)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when team has no league' do
      login_user
      let(:team) { create(:team, league: nil) }

      before do
        get team_path(team)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
    end
  end

  describe 'POST #create' do
    let(:human_name) { 'Forza' }
    let(:logo_url) { 'forza.png' }
    let(:params) do
      {
        team: {
          human_name: human_name,
          logo_url: logo_url
        }
      }
    end

    context 'when user is logged out' do
      before do
        post teams_path(params)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in without tournament_id' do
      let(:logged_user) { create(:user, status: 'configured') }
      let(:human_name) { '' }

      before do
        sign_in logged_user
        post teams_path(params)
      end

      context 'with invalid params' do
        it { expect(response).to redirect_to(joins_path) }
        it { expect(response).to have_http_status(:found) }
      end
    end

    context 'when user joins via the new flow (tournament_id present)' do
      let(:tournament) { create(:tournament) }
      let(:logged_user) { create(:user, status: :configured) }
      let(:join_params) do
        {
          team: {
            human_name: 'Forza',
            logo_url: 'forza.png',
            code: 'FRZ',
            tournament_id: tournament.id
          }
        }
      end

      before do
        sign_in logged_user
        post teams_path(join_params)
      end

      it 'creates the team' do
        expect(Team.last.human_name).to eq('Forza')
      end

      it 'uses the user-provided code' do
        expect(Team.last.code).to eq('FRZ')
      end

      it 'creates an initial Join record' do
        expect(Join.last).to have_attributes(
          user: logged_user,
          tournament: tournament,
          status: 'initial'
        )
      end

      it 'creates a draft AuctionBid without auction_round' do
        expect(AuctionBid.last).to have_attributes(
          team: Team.last,
          auction_round: nil
        )
      end

      it 'redirects to the auction bid page' do
        expect(response).to redirect_to(auction_bid_path(AuctionBid.last))
      end
    end

    context 'when user joins with blank team_id (new team, submitted from form)' do
      let(:tournament) { create(:tournament) }
      let(:logged_user) { create(:user, status: :configured) }
      let(:join_params) do
        {
          team: {
            human_name: 'Forza',
            logo_url: 'forza.png',
            code: 'FRZ',
            tournament_id: tournament.id,
            team_id: ''
          }
        }
      end

      before do
        sign_in logged_user
        post teams_path(join_params)
      end

      it 'creates the team without raising UnknownAttributeError' do
        expect(Team.last.human_name).to eq('Forza')
      end

      it 'redirects to the auction bid page' do
        expect(response).to redirect_to(auction_bid_path(AuctionBid.last))
      end
    end

    context 'when user tries to join a tournament they already applied to' do
      let(:tournament) { create(:tournament) }
      let(:logged_user) { create(:user, status: :configured) }
      let(:join_params) do
        {
          team: {
            human_name: 'Forza',
            logo_url: 'forza.png',
            code: 'FRZ',
            tournament_id: tournament.id
          }
        }
      end

      before do
        create(:join, user: logged_user, tournament: tournament, team: create(:team), status: :pending)
        sign_in logged_user
        post teams_path(join_params)
      end

      it 'does not create a second Join record' do
        expect(Join.where(user: logged_user, tournament: tournament).count).to eq(1)
      end

      it 'redirects to join path with alert' do
        expect(response).to redirect_to(joins_path)
      end
    end
  end

  describe 'GET #edit' do
    before do
      get edit_team_path(team)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team) }

      before do
        sign_in logged_user
        get edit_team_path(team)
      end

      it { expect(response).to redirect_to(user_path(logged_user)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }

      before do
        sign_in logged_user
        get edit_team_path(team)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:team)).not_to be_nil }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:logged_user) { create(:user) }
    let(:team) { create(:team, user: logged_user) }
    let(:human_name) { 'Forza' }
    let(:code) { 'FRZ' }
    let(:logo_url) { 'default_logo.png' }
    let(:params) do
      {
        team: {
          human_name: human_name,
          code: code,
          logo_url: logo_url
        }
      }
    end

    before do
      put team_path(team, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      let(:team) { create(:team) }

      before do
        sign_in logged_user
        put team_path(team, params)
      end

      it { expect(response).to redirect_to(user_path(logged_user)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and invalid params when user is logged in' do
      let(:human_name) { 'Forza Milan! Forza Milan! Forza Milan! Forza Milan!' }

      before do
        sign_in logged_user
        put team_path(team, params)
      end

      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }

      it 'does not update team human_name' do
        expect(team.reload.human_name).to eq(team.human_name)
      end

      it 'does not update team logo_url' do
        expect(team.reload.logo_url).to eq(team.logo_url)
      end
    end

    context 'with own team and valid params when user is logged in' do
      before do
        sign_in logged_user
        put team_path(team, params)
      end

      it { expect(response).to redirect_to(user_path(logged_user)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates team human_name' do
        expect(team.reload.human_name).to eq(human_name)
      end

      it 'updates team code' do
        expect(team.reload.code).to eq(code)
      end

      it 'updates team logo_url' do
        expect(team.reload.logo_url).to eq(logo_url)
      end
    end
  end
end

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

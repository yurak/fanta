RSpec.describe 'Joins' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get joins_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when user is logged in' do
      let(:user) { create(:user) }

      before { sign_in user }

      context 'with open mantra tournaments' do
        let!(:tournament) { create(:tournament) }

        before { get joins_path }

        it { expect(response).to be_successful }
        it { expect(response).to render_template(:index) }

        it 'shows available tournaments' do
          expect(response.body).to include(tournament.name)
        end
      end

      context 'when user has a non-rejected join for a tournament' do
        let!(:tournament) { create(:tournament) }
        let(:team) { create(:team) }

        before do
          create(:auction_bid, team: team, auction_round: nil)
          create(:join, :pending, user: user, tournament: tournament, team: team)
          get joins_path
        end

        it 'excludes that tournament from available list' do
          expect(controller.instance_variable_get(:@tournaments).map(&:id)).not_to include(tournament.id)
        end
      end

      context 'when user has an active team in a tournament' do
        let(:tournament) { create(:tournament) }
        let(:league) { create(:active_league, tournament: tournament) }

        before do
          create(:team, league: league, user: user)
          get joins_path
        end

        it 'excludes that tournament from available list' do
          expect(controller.instance_variable_get(:@tournaments).map(&:id)).not_to include(tournament.id)
        end

        it 'sets @has_active_leagues to true' do
          expect(assigns(:has_active_leagues)).to be(true)
        end
      end

      context 'when user has no active leagues' do
        before { get joins_path }

        it 'sets @has_active_leagues to false' do
          expect(assigns(:has_active_leagues)).to be(false)
        end
      end

      context 'when user has a rejected join for a tournament' do
        let!(:tournament) { create(:tournament) }

        before do
          create(:join, :rejected, user: user, tournament: tournament, team: create(:team))
          get joins_path
        end

        it 'still includes that tournament in available list' do
          expect(controller.instance_variable_get(:@tournaments).map(&:id)).to include(tournament.id)
        end
      end

      context 'when tournament has open_join: false' do
        let!(:closed_tournament) { create(:tournament, open_join: false) }

        before { get joins_path }

        it 'does not include closed tournament in available list' do
          expect(controller.instance_variable_get(:@tournaments).map(&:id)).not_to include(closed_tournament.id)
        end
      end

      context 'with existing non-rejected joins' do
        let(:tournament) { create(:tournament) }
        let(:team) { create(:team) }
        let!(:join) { create(:join, :pending, user: user, tournament: tournament, team: team) }

        before do
          create(:auction_bid, team: team, auction_round: nil)
          get joins_path
        end

        it 'exposes user joins' do
          expect(controller.instance_variable_get(:@user_joins)).to include(join)
        end
      end

      context 'when join team bid is attached to an auction round (after league activation)' do
        let(:tournament) { create(:tournament) }
        let(:team) { create(:team) }

        before do
          create(:join, :pending, user: user, tournament: tournament, team: team)
          create(:auction_bid, team: team)
          get joins_path
        end

        it { expect(response).to be_successful }
        it { expect(response).to render_template(:index) }
      end

      context 'with rejected joins' do
        let(:team) { create(:team) }
        let!(:rejected_join) do
          create(:join, :rejected, user: user, tournament: create(:tournament), team: team)
        end

        before do
          create(:auction_bid, team: team, auction_round: nil)
          get joins_path
        end

        it 'excludes rejected joins from user joins list' do
          expect(controller.instance_variable_get(:@user_joins)).not_to include(rejected_join)
        end
      end
    end
  end

  describe 'GET #show' do
    let(:user) { create(:user) }
    let(:tournament) { create(:tournament) }
    let(:team) { create(:team) }

    context 'when user is logged out' do
      let(:join) { create(:join, tournament: tournament, team: team) }

      before { get join_path(join) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when user is logged in' do
      before { sign_in user }

      context 'when join belongs to current user' do
        let(:join) { create(:join, user: user, tournament: tournament, team: team) }

        before { get join_path(join) }

        it { expect(response).to be_successful }
        it { expect(response).to render_template(:show) }

        it 'assigns the join' do
          expect(assigns(:join)).to eq(join)
        end
      end

      context 'when join belongs to another user' do
        let(:join) { create(:join, user: create(:user), tournament: tournament, team: team) }

        before { get join_path(join) }

        it { expect(response).to redirect_to(joins_path) }
      end

      context 'when join does not exist' do
        before { get join_path(0) }

        it { expect(response).to redirect_to(joins_path) }
      end
    end
  end
end

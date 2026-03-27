RSpec.describe 'Joins' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get joins_path }

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user

      before { get joins_path }

      it { expect(response).to be_successful }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when user already has a pending join for a tournament' do
      let(:user) { create(:user) }
      let(:tournament) { create(:tournament) }
      let!(:team) { create(:team, user: user) }

      before do
        create(:active_league, tournament: tournament)
        create(:join, user: user, tournament: tournament, team: team, status: :pending)
        create(:auction_bid, team: team, auction_round: nil)
        sign_in user
        get joins_path
      end

      it 'excludes already-applied tournaments' do
        expect(assigns(:tournaments)).not_to include(tournament)
      end
    end

    context 'when user has a team in an active league for a tournament' do
      let(:user) { create(:user) }
      let(:tournament) { create(:tournament) }

      before do
        active_league = create(:active_league, tournament: tournament)
        create(:team, user: user, league: active_league)
        sign_in user
        get joins_path
      end

      it 'excludes tournaments where user already has an active team' do
        expect(assigns(:tournaments)).not_to include(tournament)
      end

      it 'sets @has_active_leagues to true' do
        expect(assigns(:has_active_leagues)).to be(true)
      end
    end

    context 'when user has a rejected join for a tournament' do
      let(:user) { create(:user) }
      let(:tournament) { create(:tournament) }
      let!(:team) { create(:team) }

      before do
        create(:active_league, tournament: tournament)
        create(:join, user: user, tournament: tournament, team: team, status: :rejected)
        sign_in user
        get joins_path
      end

      it 'includes tournaments with rejected joins' do
        expect(assigns(:tournaments)).to include(tournament)
      end
    end

    context 'when user has no active leagues' do
      let(:user) { create(:user) }

      before do
        sign_in user
        get joins_path
      end

      it 'sets @has_active_leagues to false' do
        expect(assigns(:has_active_leagues)).to be(false)
      end
    end

    context 'when user has non-rejected joins' do
      let(:user) { create(:user) }
      let(:team) { create(:team, user: user) }

      before do
        create(:join, :pending, user: user, team: team)
        create(:auction_bid, team: team, auction_round: nil)
        sign_in user
        get joins_path
      end

      it 'includes pending joins in @user_joins' do
        expect(assigns(:user_joins).map(&:id)).to include(team.join.id)
      end
    end

    context 'when user has a rejected join' do
      let(:user) { create(:user) }
      let(:team) { create(:team, user: user) }

      before do
        create(:join, :rejected, user: user, team: team)
        sign_in user
        get joins_path
      end

      it 'excludes rejected joins from @user_joins' do
        expect(assigns(:user_joins)).to be_empty
      end
    end
  end

  describe 'GET #show' do
    context 'when user is logged out' do
      let(:join) { create(:join) }

      before { get join_path(join) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when join belongs to current user' do
      let(:user) { create(:user) }
      let(:join) { create(:join, user: user) }

      before do
        sign_in user
        get join_path(join)
      end

      it { expect(response).to have_http_status(:ok) }

      it 'assigns the join' do
        expect(assigns(:join)).to eq(join)
      end
    end

    context 'when join belongs to another user' do
      let(:user) { create(:user) }
      let(:other_join) { create(:join) }

      before do
        sign_in user
        get join_path(other_join)
      end

      it 'redirects to joins index' do
        expect(response).to redirect_to(joins_path)
      end
    end

    context 'when join does not exist' do
      login_user

      before { get join_path(id: 0) }

      it 'redirects to joins index' do
        expect(response).to redirect_to(joins_path)
      end
    end
  end
end

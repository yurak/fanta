RSpec.describe 'Join' do
  describe 'GET #index' do
    context 'when user is logged out' do
      before { get join_path }

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user

      before { get join_path }

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
        get join_path
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
        get join_path
      end

      it 'excludes tournaments where user already has an active team' do
        expect(assigns(:tournaments)).not_to include(tournament)
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
        get join_path
      end

      it 'includes tournaments with rejected joins' do
        expect(assigns(:tournaments)).to include(tournament)
      end
    end
  end
end

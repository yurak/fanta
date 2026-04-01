RSpec.describe 'Manage::Joins' do
  let(:tournament) { create(:tournament) }
  let(:league) { create(:active_league, tournament: tournament) }
  let(:team) { create(:team) }
  let(:applicant) { create(:user) }
  let!(:join) { create(:join, :pending, user: applicant, tournament: tournament, team: team) }

  describe 'GET #index' do
    context 'when user is logged out' do
      before { get manage_joins_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_joins_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      let!(:initial_join) { create(:join, user: create(:user), tournament: tournament, team: create(:team)) }
      let!(:approved_join) do
        create(:join, :approved, user: create(:user), tournament: tournament, team: create(:team, league: league))
      end

      before { get manage_joins_path }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'assigns pending joins' do
        get manage_joins_path(tab: 'pending')
        expect(response.body).to include(join.user.name)
      end

      it 'assigns initial joins' do
        get manage_joins_path(tab: 'initial')
        expect(response.body).to include(initial_join.user.name)
      end

      it 'assigns approved joins' do
        get manage_joins_path(tab: 'approved')
        expect(response.body).to include(approved_join.user.name)
      end
    end
  end

  describe 'POST #approve' do
    context 'when user is logged out' do
      before { post approve_manage_join_path(join, league_id: league.id) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { post approve_manage_join_path(join, league_id: league.id) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin approves a join' do
      login_admin

      before { post approve_manage_join_path(join, league_id: league.id) }

      it 'updates join status to approved' do
        expect(join.reload.status).to eq('approved')
      end

      it 'assigns the league to the team' do
        expect(team.reload.league).to eq(league)
      end

      it { expect(response).to redirect_to(manage_joins_path) }
    end

    context 'when approving a join that has a draft bid with an active auction' do
      login_admin

      let(:auction_round) { create(:auction_round) }
      let!(:bid) { create(:auction_bid, team: team, auction_round: nil) }

      before do
        create(:auction, league: league, status: :blind_bids, auction_rounds: [auction_round])
        post approve_manage_join_path(join, league_id: league.id)
      end

      it 'links the bid to the last auction round' do
        expect(bid.reload.auction_round).to eq(auction_round)
      end
    end

    context 'when approving a join that has a draft bid but no active auction' do
      login_admin

      let!(:bid) { create(:auction_bid, team: team, auction_round: nil) }

      before { post approve_manage_join_path(join, league_id: league.id) }

      it 'leaves the bid without an auction round' do
        expect(bid.reload.auction_round).to be_nil
      end
    end
  end

  describe 'POST #reject' do
    context 'when user is logged out' do
      before { post reject_manage_join_path(join) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { post reject_manage_join_path(join) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin rejects a join' do
      login_admin

      before { post reject_manage_join_path(join) }

      it 'updates join status to rejected' do
        expect(join.reload.status).to eq('rejected')
      end

      it { expect(response).to redirect_to(manage_joins_path) }
    end
  end
end

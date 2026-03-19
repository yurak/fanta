RSpec.describe 'Admin::Joins' do
  let(:tournament) { create(:tournament) }
  let(:league) { create(:active_league, tournament: tournament) }
  let(:team) { create(:team) }
  let(:applicant) { create(:user) }
  let!(:join) { create(:join, user: applicant, tournament: tournament, team: team, status: :pending) }

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

      before { get manage_joins_path }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'lists pending joins' do
        expect(assigns(:joins)).to include(join)
      end
    end
  end

  describe 'POST #approve' do
    context 'when admin approves a join' do
      login_admin

      before { post approve_manage_join_path(join, league_id: league.id) }

      it 'updates join status to approved' do
        expect(join.reload.status).to eq('approved')
      end

      it 'assigns the league to the team' do
        expect(team.reload.league).to eq(league)
      end

      it 'redirects to admin joins index' do
        expect(response).to redirect_to(manage_joins_path)
      end
    end

    context 'when approving a join that has a draft bid' do
      let(:auction_round) { create(:auction_round) }
      let(:bid) { create(:auction_bid, team: team, auction_round: nil) }

      login_admin

      before do
        create(:auction, league: league, status: :blind_bids, auction_rounds: [auction_round])
        bid
        post approve_manage_join_path(join, league_id: league.id)
      end

      it 'links the bid to the active auction round' do
        expect(bid.reload.auction_round).to eq(auction_round)
      end
    end

    context 'when regular user tries to approve' do
      login_user

      before { post approve_manage_join_path(join, league_id: league.id) }

      it { expect(response).to redirect_to(leagues_path) }
    end
  end

  describe 'POST #reject' do
    context 'when admin rejects a join' do
      login_admin

      before { post reject_manage_join_path(join) }

      it 'updates join status to rejected' do
        expect(join.reload.status).to eq('rejected')
      end

      it 'redirects to admin joins index' do
        expect(response).to redirect_to(manage_joins_path)
      end
    end

    context 'when regular user tries to reject' do
      login_user

      before { post reject_manage_join_path(join) }

      it { expect(response).to redirect_to(leagues_path) }
    end
  end
end

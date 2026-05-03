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

      context 'with telegram badge' do
        context 'when user has bot connected' do
          let(:applicant) { create(:user) }

          before do
            create(:user_profile, user: applicant, bot_enabled: true)
            get manage_joins_path(tab: 'pending')
          end

          it 'shows connected badge' do
            expect(response.body).to include('badge-tg-connected')
          end
        end

        context 'when user has bot disconnected' do
          before { get manage_joins_path(tab: 'pending') }

          it 'shows disconnected badge' do
            expect(response.body).to include('badge-tg-disconnected')
          end
        end
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

  context 'with pending tab sub-tabs' do
    login_admin

    let(:tournament2) { create(:tournament) }
    let!(:join2) { create(:join, :pending, user: create(:user), tournament: tournament2, team: create(:team)) }

    before { get manage_joins_path(tab: 'pending') }

    it 'groups pending_by_tournament for both tournaments' do
      expect(assigns(:pending_by_tournament).keys).to contain_exactly(tournament, tournament2)
    end

    it 'shows a sub-tab for each tournament' do
      expect(response.body).to include(CGI.escapeHTML(tournament.name)).and include(CGI.escapeHTML(tournament2.name))
    end

    it 'shows count for tournament in sub-tab' do
      expect(response.body).to include(CGI.escapeHTML("#{tournament.name} (1)"))
    end

    it 'shows count for tournament2 in sub-tab' do
      expect(response.body).to include(CGI.escapeHTML("#{tournament2.name} (1)"))
    end

    it 'shows all-tournaments tab with total count' do
      expect(response.body).to include('(2)')
    end

    it 'sets tournament_id to nil when no filter' do
      expect(assigns(:tournament_id)).to be_nil
    end

    it 'shows joins from all tournaments' do
      expect(response.body).to include(join.user.name).and include(join2.user.name)
    end

    context 'when filtering by tournament_id' do
      before { get manage_joins_path(tab: 'pending', tournament_id: tournament.id) }

      it 'assigns tournament_id' do
        expect(assigns(:tournament_id)).to eq(tournament.id)
      end

      it 'shows only joins for the selected tournament' do
        expect(response.body).to include(join.user.name)
      end

      it 'excludes joins from other tournaments' do
        expect(response.body).not_to include(join2.user.name)
      end

      it 'still renders all tournament sub-tabs' do
        expect(response.body).to include(tournament.name).and include(tournament2.name)
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

      before do
        create(:auction, league: league, status: :blind_bids, auction_rounds: [auction_round])
        post approve_manage_join_path(join, league_id: league.id)
      end

      it 'links the bid to the last auction round' do
        expect(join.auction_bid.reload.auction_round).to eq(auction_round)
      end
    end

    context 'when approving a join that has a draft bid but no active auction' do
      login_admin

      before { post approve_manage_join_path(join, league_id: league.id) }

      it 'leaves the bid without an auction round' do
        expect(join.auction_bid.reload.auction_round).to be_nil
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

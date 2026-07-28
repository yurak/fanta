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
        expect(response.body).to include(CGI.escapeHTML(join.user.name))
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
        expect(response.body).to include(CGI.escapeHTML(initial_join.user.name))
      end

      it 'assigns approved joins' do
        get manage_joins_path(tab: 'approved')
        expect(response.body).to include(CGI.escapeHTML(approved_join.user.name))
      end
    end

    context 'with a leftover pending join from a past season' do
      login_admin

      before do
        create(:join, :pending, user: create(:user, name: 'Stalezz Applicantzz'),
                                tournament: tournament, team: create(:team), season: Season.first)
        join.update!(season: create(:season, start_year: 2030, end_year: 2031))
        get manage_joins_path(tab: 'pending')
      end

      it { expect(response.body).to include(CGI.escapeHTML(join.user.name)) }
      it { expect(response.body).not_to include('Stalezz Applicantzz') }
    end
  end

  context 'with pending tab sub-tabs' do
    login_admin

    # Deterministic, non-colliding marker names: Faker first names (e.g. "Leah")
    # can be substrings of page chrome like "Leagues" and make include/exclude specs flaky.
    let(:applicant) { create(:user, name: 'Zmarkjoinone') }
    let(:tournament2) { create(:tournament) }
    let!(:join2) { create(:join, :pending, user: create(:user, name: 'Zmarkjointwo'), tournament: tournament2, team: create(:team)) }

    before { get manage_joins_path(tab: 'pending') }

    it 'groups pending_by_tournament for both tournaments' do
      expect(assigns(:tournament_counts).keys).to contain_exactly(tournament, tournament2)
    end

    it 'shows a sub-tab for each tournament' do
      expect(response.body).to include(CGI.escapeHTML(tournament.name)).and include(CGI.escapeHTML(tournament2.name))
    end

    it 'shows count for tournament in sub-tab' do
      expect(response.body).to match(/tournament_id=#{tournament.id}.*?default-tab-name">1</m)
    end

    it 'shows count for tournament2 in sub-tab' do
      expect(response.body).to match(/tournament_id=#{tournament2.id}.*?default-tab-name">1</m)
    end

    it 'shows all-tournaments tab with total count' do
      expect(response.body).to match(/title="#{Regexp.escape(I18n.t('manage.joins.all_tournaments'))}".*?default-tab-name">2</m)
    end

    it 'sets tournament_id to nil when no filter' do
      expect(assigns(:tournament_id)).to be_nil
    end

    it 'shows joins from all tournaments' do
      expect(response.body).to include(CGI.escapeHTML(join.user.name)).and include(CGI.escapeHTML(join2.user.name))
    end

    context 'when filtering by tournament_id' do
      before { get manage_joins_path(tab: 'pending', tournament_id: tournament.id) }

      it 'assigns tournament_id' do
        expect(assigns(:tournament_id)).to eq(tournament.id)
      end

      it 'shows only joins for the selected tournament' do
        expect(response.body).to include(CGI.escapeHTML(join.user.name))
      end

      it 'excludes joins from other tournaments' do
        expect(response.body).not_to include(CGI.escapeHTML(join2.user.name))
      end

      it 'still renders all tournament sub-tabs' do
        expect(response.body).to include(CGI.escapeHTML(tournament.name)).and include(CGI.escapeHTML(tournament2.name))
      end
    end
  end

  context 'with initial tab sub-tabs' do
    login_admin

    it 'groups tournament counts for the initial tab' do
      other = create(:tournament)
      create(:join, tournament: tournament, team: create(:team))
      create(:join, tournament: other, team: create(:team))
      get manage_joins_path(tab: 'initial')
      expect(assigns(:tournament_counts).keys).to contain_exactly(tournament, other)
    end

    it 'shows only the selected tournament when filtered' do
      here = create(:join, user: create(:user, name: 'Zinithere'), tournament: tournament, team: create(:team))
      get manage_joins_path(tab: 'initial', tournament_id: tournament.id)
      expect(response.body).to include(CGI.escapeHTML(here.user.name))
    end

    it 'excludes other tournaments when filtered' do
      elsewhere = create(:join, user: create(:user, name: 'Zinitelse'), tournament: create(:tournament), team: create(:team))
      get manage_joins_path(tab: 'initial', tournament_id: tournament.id)
      expect(response.body).not_to include(CGI.escapeHTML(elsewhere.user.name))
    end
  end

  context 'with approved tab sub-tabs' do
    login_admin

    it 'groups tournament counts for the approved tab' do
      other = create(:tournament)
      create(:join, :approved, tournament: tournament, team: create(:team, league: league))
      create(:join, :approved, tournament: other, team: create(:team, league: create(:active_league, tournament: other)))
      get manage_joins_path(tab: 'approved')
      expect(assigns(:tournament_counts).keys).to contain_exactly(tournament, other)
    end

    it 'shows only the selected tournament when filtered' do
      here = create(:join, :approved, user: create(:user, name: 'Zapprhere'), tournament: tournament, team: create(:team, league: league))
      get manage_joins_path(tab: 'approved', tournament_id: tournament.id)
      expect(response.body).to include(CGI.escapeHTML(here.user.name))
    end

    it 'excludes other tournaments when filtered' do
      other = create(:tournament)
      elsewhere = create(:join, :approved, user: create(:user, name: 'Zapprelse'), tournament: other,
                                           team: create(:team, league: create(:active_league, tournament: other)))
      get manage_joins_path(tab: 'approved', tournament_id: tournament.id)
      expect(response.body).not_to include(CGI.escapeHTML(elsewhere.user.name))
    end
  end

  context 'with search' do
    login_admin

    let(:applicant) { create(:user, name: 'Zsearchone') }
    let(:team) { create(:team, human_name: 'Zebra United') }
    let!(:other_join) do
      create(:join, :pending, user: create(:user, name: 'Zsearchtwo'),
                              tournament: tournament, team: create(:team, human_name: 'Lion Rovers'))
    end

    context 'when filtering by user_id on the pending tab' do
      before { get manage_joins_path(tab: 'pending', user_id: applicant.id) }

      it 'shows the matching applicant' do
        expect(response.body).to include(CGI.escapeHTML(applicant.name))
      end

      it 'excludes non-matching applicants' do
        expect(response.body).not_to include(CGI.escapeHTML(other_join.user.name))
      end
    end

    context 'when filtering by team name on the pending tab' do
      before { get manage_joins_path(tab: 'pending', team_name: 'zebra') }

      it 'shows the matching team owner' do
        expect(response.body).to include(CGI.escapeHTML(applicant.name))
      end

      it 'excludes non-matching teams' do
        expect(response.body).not_to include(CGI.escapeHTML(other_join.user.name))
      end

      it 'reflects the search in the sub-tab counts' do
        expect(response.body).to match(/tournament_id=#{tournament.id}.*?default-tab-name">1</m)
      end
    end

    context 'when filtering the In Progress (initial) tab' do
      let!(:initial_join) do
        create(:join, user: create(:user, name: 'Zinitialmark'), tournament: tournament,
                      team: create(:team, human_name: 'Falcon Squad'))
      end

      before { get manage_joins_path(tab: 'initial', team_name: 'falcon') }

      it 'shows the matching initial join' do
        expect(response.body).to include(CGI.escapeHTML(initial_join.user.name))
      end

      it 'excludes pending joins that do not match' do
        expect(response.body).not_to include(CGI.escapeHTML(applicant.name))
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

      it { expect(response).to redirect_to(manage_joins_path(tab: 'pending')) }
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

      it { expect(response).to redirect_to(manage_joins_path(tab: 'pending')) }
    end
  end
end

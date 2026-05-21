RSpec.describe 'FantaJoins' do
  let(:tournament) { create(:fanta_tournament) }
  let(:league) { create(:active_league, tournament: tournament, open_for_join: true) }
  let(:valid_params) do
    { join_code: league.join_code, team: { tournament_id: tournament.id, human_name: 'My Team', code: 'MT' } }
  end

  describe 'POST #create' do
    context 'when user is logged out' do
      it 'redirects to sign in' do
        post fanta_joins_path, params: valid_params
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    context 'when user is logged in' do
      login_user

      context 'with a valid code' do
        before { post fanta_joins_path, params: valid_params }

        it { expect(response).to redirect_to(league_path(league)) }
        it { expect(response).to have_http_status(:found) }

        it 'creates a team in the league' do
          expect(Team.last.league).to eq(league)
        end

        it 'creates a result for the team' do
          expect(Result.find_by(team: Team.last, league: league)).to be_present
        end
      end

      context 'without a join code' do
        let!(:default_league) do
          create(:active_league, tournament: tournament, open_for_join: true, default_for_join: true)
        end

        before { post fanta_joins_path, params: valid_params.merge(join_code: '') }

        it { expect(response).to redirect_to(league_path(default_league)) }

        it 'creates a team in the default league' do
          expect(Team.last.league).to eq(default_league)
        end
      end

      context 'with an invalid code and a default league' do
        let!(:default_league) do
          create(:active_league, tournament: tournament, open_for_join: true, default_for_join: true)
        end

        before { post fanta_joins_path, params: valid_params.merge(join_code: 'WRONG1') }

        it { expect(response).to redirect_to(league_path(default_league)) }

        it 'creates a team in the default league' do
          expect(Team.last.league).to eq(default_league)
        end
      end

      context 'with an invalid code and no default league' do
        before { post fanta_joins_path, params: valid_params.merge(join_code: 'WRONG1') }

        it { expect(response).to redirect_to(joins_path) }

        it 'does not create a team' do
          expect(Team.count).to eq(0)
        end
      end

      context 'when user already has a team in an open_for_join league of the same tournament' do
        before do
          other_league = create(:active_league, tournament: tournament, open_for_join: true)
          create(:team, user: User.last, tournament: tournament, league: other_league)
          post fanta_joins_path, params: valid_params
        end

        it { expect(response).to redirect_to(joins_path) }

        it 'does not create another team' do
          expect(Team.where(tournament: tournament).count).to eq(1)
        end
      end

      context 'when user has a team in a closed (non-open_for_join) league of the same tournament' do
        before do
          closed_league = create(:active_league, tournament: tournament, open_for_join: false)
          create(:team, user: User.last, tournament: tournament, league: closed_league)
          post fanta_joins_path, params: valid_params
        end

        it 'allows joining and creates a team' do
          expect(Team.where(tournament: tournament).count).to eq(2)
        end

        it { expect(response).to redirect_to(league_path(league)) }
      end
    end
  end
end

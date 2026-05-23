RSpec.describe 'Manage::WeeklyTeams' do
  describe 'GET #index' do
    context 'when logged out' do
      before { get manage_weekly_teams_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_weekly_teams_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      before { get manage_weekly_teams_path }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it 'assigns weekly_teams' do
        expect(controller.instance_variable_get(:@weekly_teams)).not_to be_nil
      end

      context 'with existing weekly teams' do
        let(:weekly_team) { create(:weekly_team, number: 5) }

        before do
          weekly_team
          get manage_weekly_teams_path
        end

        it 'includes the saved team in the list' do
          expect(response.body).to include('#5')
        end
      end
    end
  end

  describe 'GET #new' do
    context 'when logged out' do
      before { get new_manage_weekly_team_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get new_manage_weekly_team_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      context 'without round selection' do
        before { get new_manage_weekly_team_path }

        it { expect(response).to be_successful }
        it { expect(response).to render_template(:new) }

        it 'does not build teams' do
          expect(controller.instance_variable_get(:@teams)).to be_nil
        end

        it 'assigns rounds' do
          expect(controller.instance_variable_get(:@rounds)).not_to be_nil
        end
      end

      context 'with round_ids param' do
        let(:round) { create(:tournament_round) }

        before { get new_manage_weekly_team_path(round_ids: [round.id]) }

        it { expect(response).to be_successful }

        it 'builds teams' do
          expect(controller.instance_variable_get(:@teams)).not_to be_nil
        end

        it 'defaults to top mode' do
          expect(controller.instance_variable_get(:@mode)).to eq(:top)
        end
      end

      context 'with flop mode' do
        let(:round) { create(:tournament_round) }

        before { get new_manage_weekly_team_path(round_ids: [round.id], mode: 'flop') }

        it 'sets flop mode' do
          expect(controller.instance_variable_get(:@mode)).to eq(:flop)
        end
      end

      context 'with blank round_ids param' do
        before { get new_manage_weekly_team_path(round_ids: ['']) }

        it 'does not build teams' do
          expect(controller.instance_variable_get(:@teams)).to be_nil
        end
      end

      context 'with source=season and tournament_id' do
        let(:tournament) { Tournament.first }
        let(:season)     { Season.order(:start_year).last }

        before do
          round = create(:tournament_round, tournament: tournament, season: season)
          create(:round_player, :with_pos_por, score: 7, tournament_round: round)
          get new_manage_weekly_team_path(source: 'season', tournament_id: tournament.id)
        end

        it { expect(response).to be_successful }

        it 'sets source to season' do
          expect(controller.instance_variable_get(:@source)).to eq('season')
        end

        it 'builds teams' do
          expect(controller.instance_variable_get(:@teams)).not_to be_nil
        end

        it 'assigns tournaments' do
          expect(controller.instance_variable_get(:@tournaments)).not_to be_nil
        end
      end

      context 'with source=season but no tournament_id' do
        before { get new_manage_weekly_team_path(source: 'season') }

        it { expect(response).to be_successful }

        it 'does not build teams' do
          expect(controller.instance_variable_get(:@teams)).to be_nil
        end
      end

      context 'with source=avg and tournament_id' do
        let(:tournament) { Tournament.first }
        let(:season)     { Season.order(:start_year).last }

        before do
          round = create(:tournament_round, tournament: tournament, season: season)
          create(:round_player, :with_pos_por, score: 7, tournament_round: round)
          get new_manage_weekly_team_path(source: 'avg', tournament_id: tournament.id)
        end

        it { expect(response).to be_successful }

        it 'sets source to avg' do
          expect(controller.instance_variable_get(:@source)).to eq('avg')
        end

        it 'builds teams' do
          expect(controller.instance_variable_get(:@teams)).not_to be_nil
        end
      end

      context 'with source=avg but no tournament_id' do
        before { get new_manage_weekly_team_path(source: 'avg') }

        it { expect(response).to be_successful }

        it 'does not build teams' do
          expect(controller.instance_variable_get(:@teams)).to be_nil
        end
      end

      context 'with invalid source param' do
        before { get new_manage_weekly_team_path(source: 'invalid') }

        it 'falls back to round source' do
          expect(controller.instance_variable_get(:@source)).to eq('round')
        end
      end
    end
  end

  describe 'POST #create' do
    context 'when logged out' do
      before { post manage_weekly_teams_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { post manage_weekly_teams_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      let(:round)        { create(:tournament_round) }
      let(:team_module)  { TeamModule.first }
      let(:slot)         { team_module.slots.first }
      let(:round_player) { create(:round_player, :with_pos_por, score: 8, tournament_round: round) }
      let(:players)      { [{ slot_id: slot.id, round_player_id: round_player.id, total: 8.0 }] }

      before { round_player }

      context 'with valid params' do
        before do
          post manage_weekly_teams_path, params: {
            round_ids: [round.id],
            team_module_id: team_module.id,
            mode: 'top',
            number: 3,
            players: players
          }
        end

        it 'creates a WeeklyTeam' do
          expect(WeeklyTeam.count).to eq(1)
        end

        it 'redirects to the weekly team show page' do
          expect(response).to redirect_to(weekly_team_path(WeeklyTeam.last))
        end
      end

      context 'with blank number' do
        before do
          post manage_weekly_teams_path, params: {
            round_ids: [round.id],
            team_module_id: team_module.id,
            mode: 'top',
            number: '',
            players: players
          }
        end

        it 'does not create a WeeklyTeam' do
          expect(WeeklyTeam.count).to eq(0)
        end

        it 'redirects to new page' do
          expect(response).to redirect_to(new_manage_weekly_team_path)
        end
      end

      context 'with invalid team_module_id' do
        before do
          post manage_weekly_teams_path, params: {
            round_ids: [round.id],
            team_module_id: 0,
            mode: 'top',
            number: 1,
            players: players
          }
        end

        it 'does not create a WeeklyTeam' do
          expect(WeeklyTeam.count).to eq(0)
        end

        it 'redirects to new page' do
          expect(response).to redirect_to(new_manage_weekly_team_path)
        end
      end

      context 'with source=season and tournament_id' do
        let(:tournament) { Tournament.first }

        before do
          post manage_weekly_teams_path, params: {
            round_ids: [round.id],
            team_module_id: team_module.id,
            mode: 'top',
            number: 4,
            players: players,
            source: 'season',
            tournament_id: tournament.id
          }
        end

        it 'creates a WeeklyTeam with season source' do
          expect(WeeklyTeam.last.source).to eq('season')
        end

        it 'stores tournament_id' do
          expect(WeeklyTeam.last.tournament_id).to eq(tournament.id)
        end
      end

      context 'with source=avg and tournament_id' do
        let(:tournament) { Tournament.first }

        before do
          post manage_weekly_teams_path, params: {
            round_ids: [round.id],
            team_module_id: team_module.id,
            mode: 'top',
            number: 5,
            players: players,
            source: 'avg',
            tournament_id: tournament.id
          }
        end

        it 'creates a WeeklyTeam with avg source' do
          expect(WeeklyTeam.last.source).to eq('avg')
        end

        it 'stores tournament_id' do
          expect(WeeklyTeam.last.tournament_id).to eq(tournament.id)
        end
      end
    end
  end
end

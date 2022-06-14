RSpec.describe 'Teams', type: :request do
  let(:team) { create(:team) }

  describe 'GET #show' do
    let(:team) { create(:team, :with_league_matches) }

    before do
      get team_path(team)
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response).to have_http_status(:ok) }
  end

  describe 'GET #edit' do
    before do
      get edit_team_path(team)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team and league with closed transfer_status when user is logged in' do
      let(:league) { create(:league, transfer_status: :closed) }
      let(:team) { create(:team, league: league) }

      login_user
      before do
        get edit_team_path(team)
      end

      it { expect(response).to redirect_to(team_path(team)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team and league with open transfer_status when user is logged in' do
      let(:league) { create(:league, transfer_status: :open) }
      let(:team) { create(:team, league: league) }

      login_user
      before do
        get edit_team_path(team)
      end

      it { expect(response).to redirect_to(team_path(team)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and league with closed transfer_status when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:league) { create(:league, transfer_status: :closed) }
      let(:team) { create(:team, league: league, user: logged_user) }

      before do
        sign_in logged_user
        get edit_team_path(team)
      end

      it { expect(response).to redirect_to(team_path(team)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and league with sales auction when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:auction) { create(:auction, status: :sales) }
      let(:team) { create(:team, league: auction.league, user: logged_user) }

      before do
        sign_in logged_user
        get edit_team_path(team)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:team)).not_to be_nil }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:logged_user) { create(:user) }
    let(:league) { create(:league, transfer_status: :closed) }
    let(:team) { create(:team, league: league, user: logged_user) }

    let(:params) do
      {
        player_teams: {
          '12345': { transfer_status: 'transferable' }
        }
      }
    end

    before do
      put team_path(team, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team and league with closed transfer_status when user is logged in' do
      login_user
      before do
        put team_path(team, params)
      end

      it { expect(response).to redirect_to(team_path(team)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team and league with open transfer_status when user is logged in' do
      let(:league) { create(:league, transfer_status: :open) }

      login_user
      before do
        put team_path(team, params)
      end

      it { expect(response).to redirect_to(team_path(team)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and league with closed transfer_status when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, league: league, user: logged_user) }

      before do
        sign_in logged_user
        put team_path(team, params)
      end

      it { expect(response).to redirect_to(team_path(team)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and league with open transfer_status when user is logged in' do
      let(:logged_user) { create(:user) }
      let(:auction) { create(:auction, status: :sales) }
      let(:team) { create(:team, :with_players, league: auction.league, user: logged_user) }

      let(:params) do
        {
          player_teams: {
            "#{team.player_teams[0].id}": { transfer_status: 'untouchable' },
            "#{team.player_teams[1].id}": { transfer_status: 'untouchable' },
            "#{team.player_teams[2].id}": { transfer_status: 'transferable' },
            "#{team.player_teams[3].id}": { transfer_status: 'untouchable' },
            "#{team.player_teams[4].id}": { transfer_status: 'untouchable' }
          }
        }
      end

      before do
        sign_in logged_user
        put team_path(team, params)
      end

      it { expect(response).to redirect_to(team_path(team)) }
      it { expect(response).to have_http_status(:found) }

      it 'not updates player_team transfer_status when untouchable' do
        expect(team.player_teams[0].reload.transfer_status).to eq('untouchable')
      end

      it 'updates player_team transfer_status' do
        expect(team.player_teams[2].reload.transfer_status).to eq('transferable')
      end
    end
  end
end

RSpec.describe 'RoundPlayers' do
  describe 'GET #index' do
    let(:tournament_round) { create(:tournament_round) }

    context 'when user is logged out' do
      before do
        get tournament_round_round_players_path(tournament_round)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get tournament_round_round_players_path(tournament_round)
      end

      # The page itself is rendered by the React app; data comes from
      # Api::RoundPlayersController (see spec/requests/api/round_players_spec.rb).
      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'with a selected league' do
      let(:league) { create(:active_league) }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, league: league.id)
      end

      it { expect(response).to be_successful }

      it 'renders the league footer' do
        expect(response.body).to include('portrait-footer')
      end
    end
  end
end

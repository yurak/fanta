RSpec.describe 'Clubs' do
  describe 'GET #show' do
    let(:club) { create(:club) }

    context 'when user is logged out' do
      before do
        get tournament_club_path(club.tournament, club)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user

      before do
        get tournament_club_path(club.tournament, club)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when league_id param is provided' do
      let(:logged_user) { create(:user) }
      let(:league) { create(:league, tournament: club.tournament) }

      before do
        sign_in logged_user
        get tournament_club_path(club.tournament, club, league_id: league.id)
      end

      it { expect(response).to be_successful }
    end

    context 'when user has a team in the tournament and no league_id param' do
      let(:logged_user) { create(:user) }
      let(:league) { create(:league, tournament: club.tournament) }

      before do
        create(:team, user: logged_user, league: league)
        sign_in logged_user
        get tournament_club_path(club.tournament, club)
      end

      it { expect(response).to be_successful }
      it { expect(response.body).to include(league.name) }
    end

    context 'when user has no team in the tournament and no league_id param' do
      let(:logged_user) { create(:user) }

      before do
        sign_in logged_user
        get tournament_club_path(club.tournament, club)
      end

      it { expect(response).to be_successful }
    end
  end
end

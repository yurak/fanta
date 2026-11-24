RSpec.describe 'Divisions' do
  # The page is a React shell now: the tree itself comes from
  # GET /api/tournaments/:id/divisions, which spec/requests/api/divisions_spec.rb covers.
  describe 'GET #index' do
    let(:tournament) { Tournament.first }

    context 'when user is logged out' do
      before do
        get tournament_divisions_path(tournament)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get tournament_divisions_path(tournament)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }

      it 'mounts the SPA rather than rendering the tree server-side' do
        expect(response.body).to include('data-component-name="App"')
      end
    end

    context 'when the tournament carries leagues in divisions' do
      let(:division) { create(:division, level: 'A') }
      let!(:league) { create(:league, status: :active, tournament: tournament, division: division) }

      login_user
      before do
        get tournament_divisions_path(tournament)
      end

      it { expect(response).to be_successful }

      # the shell is the same whatever the data: no league name reaches the HTML
      it 'does not inline the leagues into the page' do
        expect(response.body).not_to include(league.name)
      end
    end
  end
end

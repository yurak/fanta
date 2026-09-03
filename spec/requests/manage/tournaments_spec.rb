RSpec.describe 'Manage::Tournaments' do
  describe 'GET #index' do
    context 'when logged out' do
      before { get manage_tournaments_path }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when regular user is logged in' do
      login_user

      before { get manage_tournaments_path }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when admin is logged in' do
      login_admin

      let!(:tournament) { create(:tournament, eurocup: true, open_join: false, skip_round_check: true) }

      before { get manage_tournaments_path }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response.body).to include(I18n.t('manage.tournaments.col_eurocup')) }
      it { expect(response.body).to include(I18n.t('manage.tournaments.col_open_join')) }
      it { expect(response.body).to include(I18n.t('manage.tournaments.col_skip_round_check')) }
      it { expect(response.body).to include(manage_tournament_path(tournament)) }
    end
  end

  describe 'GET #show' do
    login_admin

    let(:tournament) { create(:tournament) }

    before { get manage_tournament_path(tournament) }

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
    it { expect(response.body).to include(manage_clubs_path(tournament_id: tournament.id)) }
    it { expect(response.body).to include(CGI.escapeHTML(manage_leagues_path(tournament_id: tournament.id, status: 'active'))) }
    it { expect(response.body).to include(import_calendar_manage_tournament_path(tournament)) }
    it { expect(response.body).to include(create_rounds_manage_tournament_path(tournament)) }

    it 'renders in the ua locale' do
      I18n.with_locale(:ua) { get manage_tournament_path(tournament) }

      expect(response).to be_successful
    end
  end

  describe 'POST #create_rounds' do
    login_admin

    let(:tournament) { create(:tournament) }

    it 'creates the rounds for the current season' do
      post create_rounds_manage_tournament_path(tournament), params: { rounds_count: 5 }

      expect(tournament.tournament_rounds.by_season(Season.last.id).count).to eq(5)
    end

    it 'redirects back to the tournament' do
      post create_rounds_manage_tournament_path(tournament), params: { rounds_count: 5 }

      expect(response).to redirect_to(manage_tournament_path(tournament))
    end

    it 'refuses a non-positive count' do
      post create_rounds_manage_tournament_path(tournament), params: { rounds_count: 0 }

      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST #import_calendar' do
    login_admin

    let(:tournament) { create(:tournament, source_id: 47) }

    before { allow(TournamentMatches::CalendarImporter).to receive(:call).and_return(result) }

    context 'when matches were imported' do
      let(:result) do
        { created: 10, updated: 2, skipped: 0, failed: 0, unknown_clubs: [], missing_rounds: [] }
      end

      it { expect { post import_calendar_manage_tournament_path(tournament) }.not_to raise_error }

      it 'reports the counts' do
        post import_calendar_manage_tournament_path(tournament)

        expect(flash[:notice]).to include('10', '2')
      end
    end

    context 'when clubs are missing' do
      let(:result) do
        { created: 1, updated: 0, skipped: 2, failed: 3, unknown_clubs: ['Sabah FK'], missing_rounds: [9] }
      end

      before { post import_calendar_manage_tournament_path(tournament) }

      it { expect(flash[:notice]).to include('Sabah FK') }
      it { expect(flash[:notice]).to include('9') }
    end

    context 'when nothing came back' do
      let(:result) do
        { created: 0, updated: 0, skipped: 0, failed: 0, unknown_clubs: [], missing_rounds: [] }
      end

      before { post import_calendar_manage_tournament_path(tournament) }

      it { expect(flash[:alert]).to be_present }
    end
  end

  describe 'GET #edit' do
    login_admin

    let(:tournament) { create(:tournament) }

    before { get edit_manage_tournament_path(tournament) }

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:edit) }
  end

  describe 'PATCH #update' do
    login_admin

    let(:tournament) { create(:tournament, source: :fotmob, live_scores_enabled: false, name: 'Old') }

    it 'updates the live scores flag' do
      patch manage_tournament_path(tournament), params: { tournament: { live_scores_enabled: '1' } }

      expect(tournament.reload.live_scores_enabled).to be(true)
    end

    it 'updates other fields' do
      patch manage_tournament_path(tournament), params: { tournament: { name: 'New Name' } }

      expect(tournament.reload.name).to eq('New Name')
    end

    it 'redirects to the index' do
      patch manage_tournament_path(tournament), params: { tournament: { name: 'New Name' } }

      expect(response).to redirect_to(manage_tournaments_path)
    end
  end
end

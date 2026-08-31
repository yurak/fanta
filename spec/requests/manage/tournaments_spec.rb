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

    it 'renders in the ua locale' do
      I18n.with_locale(:ua) { get manage_tournament_path(tournament) }

      expect(response).to be_successful
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

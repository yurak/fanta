RSpec.describe 'Results' do
  describe 'GET #index' do
    context 'when user is logged out' do
      let(:league) { create(:league) }

      before do
        get league_results_path(league)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with clubs league' do
      let(:league) { create(:league) }

      login_user
      before do
        get league_results_path(league)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'with national_teams league' do
      let(:league) { create(:league, tournament: create(:tournament, :with_national_teams)) }

      login_user
      before do
        get league_results_path(league)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'with national_teams league with points order' do
      let(:league) { create(:league, tournament: create(:tournament, :with_national_teams)) }

      login_user
      before do
        get league_results_path(league, order: 'points')
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'with national_teams league with gamedays order' do
      let(:league) { create(:league, tournament: create(:tournament, :with_national_teams)) }

      login_user
      before do
        get league_results_path(league, order: 'gamedays')
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'with national_teams league with best lineup order' do
      let(:league) { create(:league, tournament: create(:tournament, :with_national_teams)) }

      login_user
      before do
        get league_results_path(league, order: 'lineup')
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
    end
  end
end

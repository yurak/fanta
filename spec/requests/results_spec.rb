RSpec.describe 'Results' do
  describe 'GET #index' do
    context 'with clubs league' do
      let(:league) { create(:league) }

      before do
        get league_results_path(league)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:results)).not_to be_nil }
    end

    context 'with national_teams league' do
      let(:league) { create(:league, tournament: create(:tournament, :with_national_teams)) }

      before do
        get league_results_path(league)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:results)).not_to be_nil }
    end

    context 'with national_teams league with points order' do
      let(:league) { create(:league, tournament: create(:tournament, :with_national_teams)) }

      before do
        get league_results_path(league, order: 'points')
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:results)).not_to be_nil }
    end

    context 'with national_teams league with gamedays order' do
      let(:league) { create(:league, tournament: create(:tournament, :with_national_teams)) }

      before do
        get league_results_path(league, order: 'gamedays')
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:results)).not_to be_nil }
    end

    context 'with national_teams league with best lineup order' do
      let(:league) { create(:league, tournament: create(:tournament, :with_national_teams)) }

      before do
        get league_results_path(league, order: 'lineup')
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:results)).not_to be_nil }
    end
  end
end

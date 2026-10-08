RSpec.describe 'Divisions' do
  describe 'GET #index' do
    let(:tournament) { Tournament.first }

    context 'when user is logged out' do
      before do
        get tournament_divisions_path(tournament)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'without league' do
      login_user
      before do
        get tournament_divisions_path(tournament)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:leagues)).to eq({}) }
    end

    context 'when tournament with league without divisions' do
      login_user
      before do
        create(:league, status: :active, tournament: tournament)
        get tournament_divisions_path(tournament)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:leagues)).to eq({}) }
    end

    context 'when tournament with league and divisions' do
      let(:division) { create(:division, level: 'A') }
      let!(:league) { create(:league, status: :active, tournament: tournament, division: division) }

      login_user
      before do
        get tournament_divisions_path(tournament)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }

      it 'returns leagues' do
        expect(assigns(:leagues)['A']).to eq([league])
      end
    end

    # The table is preloaded to keep the page off one query per league. `includes` cannot do it
    # here: next to the eager_load it folds into the same JOIN, where ordering by division level
    # wins and the standings come back in no order at all.
    context 'when a league has a table' do
      let(:division) { create(:division, level: 'A') }
      let(:league) { create(:league, status: :active, tournament: tournament, division: division) }

      login_user
      before do
        [3, 10, 7].each do |points|
          create(:result, league: league, team: create(:team, league: league), points: points)
        end

        get tournament_divisions_path(tournament)
      end

      it 'hands the view the table already in standings order' do
        expect(assigns(:leagues)['A'].first.ordered_results.map(&:points)).to eq([10, 7, 3])
      end

      it 'hands it over already loaded, teams included' do
        loaded = assigns(:leagues)['A'].first

        aggregate_failures do
          expect(loaded.association(:ordered_results)).to be_loaded
          expect(loaded.ordered_results.map { |r| r.association(:team).loaded? }).to all(be true)
        end
      end
    end
  end
end

RSpec.describe 'Divisions' do
  describe 'GET #index' do
    let(:tournament) { Tournament.first }

    context 'without league' do
      before do
        get tournament_divisions_path(tournament)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:leagues)).to eq({}) }
    end

    context 'when tournament with league without divisions' do
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
  end
end

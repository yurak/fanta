RSpec.describe LeaguesHelper do
  describe '#league_link(league)' do
    let(:league) { create(:league) }

    context 'without active tour and results' do
      it 'returns league results path' do
        expect(helper.league_link(league)).to eq(league_path(league))
      end
    end

    context 'without active tour and with results' do
      before { create(:result, league: league) }

      it 'returns league results path' do
        expect(helper.league_link(league)).to eq(league_results_path(league))
      end
    end

    context 'with active tour' do
      let!(:tour) { create(:tour, league: league) }

      it 'returns tour path' do
        expect(helper.league_link(league)).to eq(tour_path(tour))
      end
    end
  end
end

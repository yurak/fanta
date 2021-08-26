RSpec.describe LeaguesHelper, type: :helper do
  describe '#league_link(league)' do
    let(:league) { create(:league) }

    context 'without active tour' do
      it 'returns league results path' do
        expect(helper.league_link(league)).to eq(league_results_path(league))
      end
    end

    context 'with active tour' do
      it 'returns tour path' do
        tour = create(:tour, league: league)

        expect(helper.league_link(league)).to eq(tour_path(tour))
      end
    end
  end
end

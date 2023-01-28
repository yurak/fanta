RSpec.describe TeamsHelper do
  describe '#team_league_link(league)' do
    let(:league) { create(:league) }

    context 'without league' do
      let(:league) { nil }

      it 'returns empty string' do
        expect(helper.team_league_link(league)).to eq('')
      end
    end

    context 'when league without active tour' do
      it 'returns results path' do
        expect(helper.team_league_link(league)).to eq(league_results_path(league))
      end
    end

    context 'when league with active tour' do
      let!(:tour) { create(:tour, league: league) }

      it 'returns active tour path' do
        expect(helper.team_league_link(league)).to eq(tour_path(tour))
      end
    end
  end
end

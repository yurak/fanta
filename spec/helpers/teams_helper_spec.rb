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

  describe '#season_label' do
    it 'spells the years out, as the season tables elsewhere do' do
      season = build(:season, start_year: 2026, end_year: 2027)

      expect(helper.season_label(season)).to eq('2026-2027')
    end

    it 'says nothing for a missing season' do
      expect(helper.season_label(nil)).to eq('')
    end
  end
end

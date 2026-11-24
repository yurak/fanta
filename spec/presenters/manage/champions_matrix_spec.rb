RSpec.describe Manage::ChampionsMatrix do
  subject(:matrix) { described_class.new([champion, runner_up]) }

  let(:champion) { create(:user, champion_number: 1) }
  let(:runner_up) { create(:user, champion_number: 2) }
  let(:italy) { Tournament.find_by!(code: 'italy') }
  let(:spain) { Tournament.find_by!(code: 'spain') }

  before do
    create(:user_title, user: champion, tournament: italy, championship_number: 1, season: '2023/2024')
    create(:user_title, user: champion, tournament: italy, championship_number: 2, season: '2024/2025')
    create(:user_title, user: champion, tournament: spain, championship_number: 3, season: '2024/2025')
    create(:user_title, user: runner_up, tournament: spain, championship_number: 1, season: '2024')
  end

  describe '#tournaments' do
    it 'lists only the tournaments that were won, ordered by id' do
      expect(matrix.tournaments).to eq([italy, spain].sort_by(&:id))
    end

    it 'leaves out a title with no tournament' do
      create(:user_title, user: champion, tournament: nil, championship_number: 4, season: '2025/2026')

      expect(matrix.tournaments).to eq([italy, spain].sort_by(&:id))
    end
  end

  describe '#seasons' do
    # "2024" is a calendar-year league: it belongs between the two split seasons, not after them
    it 'sorts a calendar year between the split seasons that share its start' do
      expect(matrix.seasons).to eq(%w[2023/2024 2024 2024/2025])
    end
  end

  describe '#titles_in' do
    it 'counts the titles won in a tournament' do
      expect(matrix.titles_in(champion, italy)).to eq(2)
    end

    it 'returns zero for a tournament the champion never won' do
      expect(matrix.titles_in(runner_up, italy)).to eq(0)
    end
  end

  describe '#titles_in_season' do
    it 'counts the titles won in a season' do
      expect(matrix.titles_in_season(champion, '2024/2025')).to eq(2)
    end

    it 'returns zero for a season the champion sat out' do
      expect(matrix.titles_in_season(champion, '2024')).to eq(0)
    end
  end

  describe '#total' do
    it 'adds up to the same figure as either half of the board' do
      by_tournament = matrix.tournaments.sum { |tournament| matrix.titles_in(champion, tournament) }
      by_season = matrix.seasons.sum { |season| matrix.titles_in_season(champion, season) }

      expect([matrix.total(champion), by_tournament, by_season]).to eq([3, 3, 3])
    end
  end

  describe '#shade' do
    it 'leaves an empty cell unshaded' do
      expect(matrix.shade(0)).to be_nil
    end

    it 'shades a cell by its count' do
      expect(matrix.shade(3)).to eq(3)
    end

    it 'keeps the last shade past the end of the scale' do
      expect(matrix.shade(described_class::MAX_SHADE + 5)).to eq(described_class::MAX_SHADE)
    end
  end

  describe '#cell_classes' do
    it 'leaves an empty cell without a shade class' do
      expect(matrix.cell_classes(0)).to eq(['champions-matrix-cell', nil])
    end

    it 'names the shade of a filled cell' do
      expect(matrix.cell_classes(2)).to eq(%w[champions-matrix-cell champions-matrix-shade-2])
    end
  end

  describe '#season_label' do
    it 'shortens a split season to its last two years' do
      expect(matrix.season_label('2025/2026')).to eq('25/26')
    end

    it 'shortens a calendar year to two digits' do
      expect(matrix.season_label('2024')).to eq('24')
    end
  end
end

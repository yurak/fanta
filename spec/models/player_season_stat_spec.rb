RSpec.describe PlayerSeasonStat do
  subject(:player_season_stat) { create(:player_season_stat) }

  describe 'Associations' do
    it { is_expected.to belong_to(:club) }
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:season) }
    it { is_expected.to belong_to(:tournament) }
  end

  describe '.by_position' do
    let!(:matched_stat) { create(:player_season_stat, position1: 'Dc', position2: 'M', position3: nil) }

    before do
      create(:player_season_stat, position1: 'Por', position2: nil, position3: nil)
    end

    it 'returns stats with matching position in any position column' do
      expect(described_class.by_position('M')).to eq([matched_stat])
    end
  end

  describe '.played_minimum' do
    let!(:matched_stat) { create(:player_season_stat, played_matches: 14) }

    before do
      create(:player_season_stat, played_matches: 13)
    end

    it 'returns stats with more than thirteen played matches' do
      expect(described_class.played_minimum).to eq([matched_stat])
    end
  end

  describe '.by_season' do
    let(:season) { create(:season) }
    let!(:matched_stat) { create(:player_season_stat, season: season) }

    before do
      create(:player_season_stat)
    end

    it 'returns stats for season' do
      expect(described_class.by_season(season)).to eq([matched_stat])
    end
  end

  describe '#position_ital_arr' do
    subject(:player_season_stat) { build(:player_season_stat, position1: 'Dc', position2: nil, position3: 'M') }

    it 'returns compacted positions' do
      expect(player_season_stat.position_ital_arr).to eq(%w[Dc M])
    end
  end
end

RSpec.describe Season do
  describe 'Associations' do
    it { is_expected.to have_many(:leagues).dependent(:destroy) }
    it { is_expected.to have_many(:player_season_stats).dependent(:destroy) }
    it { is_expected.to have_many(:tournament_rounds).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :start_year }
    it { is_expected.to validate_uniqueness_of :start_year }
    it { is_expected.to validate_numericality_of(:start_year).is_greater_than_or_equal_to(Season::MIN_START_YEAR) }
    it { is_expected.to validate_presence_of :end_year }
    it { is_expected.to validate_uniqueness_of :end_year }
    it { is_expected.to validate_numericality_of(:end_year).is_greater_than_or_equal_to(Season::MIN_END_YEAR) }
  end

  describe '#display_name' do
    it 'returns start_year/end_year format' do
      season = create(:season, start_year: 2024, end_year: 2025)
      expect(season.display_name).to eq('2024/2025')
    end
  end

  describe 'constants' do
    it 'defines minimum start year' do
      expect(described_class::MIN_START_YEAR).to eq(2019)
    end

    it 'defines minimum end year' do
      expect(described_class::MIN_END_YEAR).to eq(2020)
    end
  end
end

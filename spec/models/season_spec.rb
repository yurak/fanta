RSpec.describe Season do
  describe 'Associations' do
    it { is_expected.to have_many(:leagues).dependent(:destroy) }
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
end

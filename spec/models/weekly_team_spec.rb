RSpec.describe WeeklyTeam do
  subject(:weekly_team) { build(:weekly_team) }

  describe 'associations' do
    it { is_expected.to belong_to(:team_module) }
    it { is_expected.to belong_to(:season) }
    it { is_expected.to have_many(:weekly_team_players).dependent(:destroy) }
    it { is_expected.to have_many(:round_players).through(:weekly_team_players) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_numericality_of(:number).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:mode) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:mode).with_values(top: 'top', flop: 'flop').backed_by_column_of_type(:string) }
  end
end

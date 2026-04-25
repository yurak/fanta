RSpec.describe WeeklyTeamPlayer do
  describe 'associations' do
    it { is_expected.to belong_to(:weekly_team) }
    it { is_expected.to belong_to(:slot) }
    it { is_expected.to belong_to(:round_player) }
  end

  describe 'validations' do
    subject { create(:weekly_team_player) }

    it { is_expected.to validate_uniqueness_of(:slot_id).scoped_to(:weekly_team_id) }
  end
end

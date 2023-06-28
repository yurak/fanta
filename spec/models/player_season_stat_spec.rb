RSpec.describe PlayerSeasonStat do
  subject(:player_season_stat) { create(:player_season_stat) }

  describe 'Associations' do
    it { is_expected.to belong_to(:club) }
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:season) }
    it { is_expected.to belong_to(:tournament) }
  end
end

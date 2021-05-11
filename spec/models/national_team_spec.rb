RSpec.describe NationalTeam, type: :model do
  subject(:national_team) { create(:national_team) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to have_many(:players).dependent(:destroy) }
  end
end

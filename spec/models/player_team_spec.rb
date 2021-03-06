RSpec.describe PlayerTeam, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:team) }
  end
end

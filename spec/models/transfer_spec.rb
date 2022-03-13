RSpec.describe Transfer, type: :model do
  subject(:transfer) { create(:transfer) }

  describe 'Associations' do
    it { is_expected.to belong_to(:auction).optional }
    it { is_expected.to belong_to(:league) }
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:team) }
  end
end

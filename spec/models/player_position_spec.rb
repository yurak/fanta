RSpec.describe PlayerPosition, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:position) }
  end
end

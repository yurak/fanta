RSpec.describe PlayerRequest, type: :model do
  subject(:player_request) { create(:player_request) }

  describe 'Associations' do
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :positions }
  end
end

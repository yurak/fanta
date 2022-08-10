RSpec.describe UserProfile, type: :model do
  subject(:user_profile) { create(:user_profile) }

  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
  end
end

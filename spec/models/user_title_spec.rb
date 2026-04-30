RSpec.describe UserTitle do
  subject(:user_title) { build(:user_title) }

  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:tournament).optional }
    it { is_expected.to belong_to(:result).optional }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:championship_number) }
  end
end

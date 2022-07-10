RSpec.describe JoinRequest, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :leagues }

    it { is_expected.to define_enum_for(:status).with_values(%i[initial processed archived]) }
  end
end

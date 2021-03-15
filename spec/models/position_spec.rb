RSpec.describe Position, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:player_positions).dependent(:destroy) }
    it { is_expected.to have_many(:players).through(:player_positions) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of :name }
  end
end

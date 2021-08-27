RSpec.describe PlayerTeam, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:team) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:transfer_status).with_values(%i[untouchable transferable]) }
  end
end

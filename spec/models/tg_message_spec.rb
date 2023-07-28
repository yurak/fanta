RSpec.describe TgMessage do
  describe 'Validations' do
    it { is_expected.to validate_presence_of :update_id }
  end
end

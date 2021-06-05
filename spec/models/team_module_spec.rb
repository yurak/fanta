RSpec.describe TeamModule, type: :model do
  subject(:team_module) { create(:team_module) }

  describe 'Associations' do
    it { is_expected.to have_many(:slots).dependent(:destroy) }
    it { is_expected.to have_many(:lineups).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end

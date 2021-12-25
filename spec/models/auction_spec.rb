RSpec.describe Auction, type: :model do
  subject(:auction) { create(:auction) }

  describe 'Associations' do
    it { is_expected.to belong_to(:league) }
    it { is_expected.to have_many(:transfers).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:status).with_values(%i[initial open_bids active closed]) }
  end
end

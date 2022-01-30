RSpec.describe Auction, type: :model do
  subject(:auction) { create(:auction) }

  describe 'Associations' do
    it { is_expected.to belong_to(:league) }
    it { is_expected.to have_many(:auction_rounds).dependent(:destroy) }
    it { is_expected.to have_many(:transfers).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:status).with_values(%i[initial sales blind_bids live closed]) }
  end
end

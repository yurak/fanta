RSpec.describe Auction do
  subject(:auction) { create(:auction) }

  describe 'Associations' do
    it { is_expected.to belong_to(:league) }
    it { is_expected.to have_many(:auction_rounds).dependent(:destroy) }
    it { is_expected.to have_many(:transfers).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:status).with_values(%i[initial sales blind_bids live closed]) }
  end

  describe '#primary?' do
    context 'with number 1' do
      it 'returns true' do
        expect(auction).to be_primary
      end
    end

    context 'when number is not 1' do
      before do
        auction.update(number: 3)
      end

      it 'returns false' do
        expect(auction).not_to be_primary
      end
    end
  end
end

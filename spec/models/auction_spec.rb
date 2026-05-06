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

  describe '.initial_sales' do
    let!(:initial_auction) { create(:auction, status: :initial) }
    let!(:sales_auction) { create(:auction, status: :sales) }

    before do
      create(:auction, status: :blind_bids)
    end

    it 'returns initial and sales auctions' do
      expect(described_class.initial_sales).to contain_exactly(initial_auction, sales_auction)
    end
  end

  describe '.active' do
    let!(:sales_auction) { create(:auction, status: :sales) }
    let!(:blind_bids_auction) { create(:auction, status: :blind_bids) }
    let!(:live_auction) { create(:auction, status: :live) }

    before do
      create(:auction, status: :initial)
      create(:auction, status: :closed)
    end

    it 'returns active auction statuses' do
      expect(described_class.active).to contain_exactly(sales_auction, blind_bids_auction, live_auction)
    end
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

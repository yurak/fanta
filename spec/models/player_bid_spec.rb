RSpec.describe PlayerBid do
  subject(:player_bid) { build(:player_bid) }

  describe 'Associations' do
    it { is_expected.to belong_to(:auction_bid) }
    it { is_expected.to belong_to(:player).optional }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:status).with_values(%i[initial success failed]) }
  end

  describe '#team' do
    it 'delegates to auction bid' do
      expect(player_bid.team).to eq(player_bid.auction_bid.team)
    end
  end

  describe 'creation' do
    context 'when auction bid allows player bids' do
      it 'is valid' do
        expect(player_bid).to be_valid
      end
    end

    context 'when auction bid locks player bids' do
      before do
        player_bid.auction_bid.lock_player_bids!
      end

      it 'is invalid' do
        expect(player_bid).not_to be_valid
      end
    end
  end

  describe 'price normalization' do
    subject(:player_bid) { create(:player_bid, price: 5) }

    # Clearing the price input submits an empty string; an integer column casts that to nil, and the
    # column is NOT NULL — which used to end the request with PG::NotNullViolation and a 500.
    it 'falls back to the minimum when the field is submitted empty' do
      player_bid.update!(price: '')

      expect(player_bid.reload.price).to eq(described_class::MIN_PRICE)
    end

    it 'falls back to the minimum when the price is nil' do
      player_bid.update!(price: nil)

      expect(player_bid.reload.price).to eq(described_class::MIN_PRICE)
    end

    it 'keeps a real price' do
      player_bid.update!(price: 12)

      expect(player_bid.reload.price).to eq(12)
    end
  end
end

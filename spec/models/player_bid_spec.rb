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
end

RSpec.describe PlayerBid do
  describe 'Associations' do
    it { is_expected.to belong_to(:auction_bid) }
    it { is_expected.to belong_to(:player) }
  end
end

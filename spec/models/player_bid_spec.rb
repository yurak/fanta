RSpec.describe PlayerBid, type: :model do
  # subject(:player_bid) { create(:player_bid) }

  describe 'Associations' do
    it { is_expected.to belong_to(:auction_bid) }
    it { is_expected.to belong_to(:player) }
  end
end

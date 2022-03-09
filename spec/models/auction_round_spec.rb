RSpec.describe AuctionRound, type: :model do
  subject(:auction_round) { create(:auction_round) }

  describe 'Associations' do
    it { is_expected.to belong_to(:auction) }
    it { is_expected.to have_many(:auction_bids).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:status).with_values(%i[active processing closed]) }
  end

  describe '#bid_exist?(team)' do
    let!(:team) { create(:team) }

    context 'without auction_bids' do
      it { expect(auction_round.bid_exist?(team)).to eq(false) }
    end

    context 'without team' do
      it { expect(auction_round.bid_exist?(nil)).to eq(false) }
    end

    context 'without auction_bids of specified team' do
      before do
        create_list(:auction_bid, 3, auction_round: auction_round)
      end

      it { expect(auction_round.bid_exist?(team)).to eq(false) }
    end

    context 'with auction_bids of specified team' do
      before do
        create(:auction_bid, auction_round: auction_round, team: team)
      end

      it { expect(auction_round.bid_exist?(team)).to eq(true) }
    end
  end
end

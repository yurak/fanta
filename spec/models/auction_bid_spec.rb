RSpec.describe AuctionBid do
  subject(:auction_bid) { create(:auction_bid) }

  describe 'Associations' do
    it { is_expected.to belong_to(:auction_round).optional }
    it { is_expected.to belong_to(:team) }
    it { is_expected.to have_many(:player_bids).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:status).with_values(%i[initial ongoing submitted completed processed]) }
  end

  describe '.initial_ongoing' do
    let!(:initial_bid) { create(:auction_bid, status: :initial) }
    let!(:ongoing_bid) { create(:auction_bid, status: :ongoing) }

    before do
      create(:auction_bid, status: :submitted)
    end

    it 'returns initial and ongoing bids' do
      expect(described_class.initial_ongoing).to contain_exactly(initial_bid, ongoing_bid)
    end
  end

  describe '#auction' do
    it 'delegates to auction round' do
      expect(auction_bid.auction).to eq(auction_bid.auction_round.auction)
    end

    context 'without auction round' do
      let(:auction_bid) { create(:auction_bid, auction_round: nil) }

      it 'returns nil' do
        expect(auction_bid.auction).to be_nil
      end
    end
  end

  describe '#editable?' do
    %i[initial ongoing submitted].each do |status|
      context "with #{status} status" do
        let(:auction_bid) { build(:auction_bid, status: status) }

        it 'returns true' do
          expect(auction_bid).to be_editable
        end
      end
    end

    %i[completed processed].each do |status|
      context "with #{status} status" do
        let(:auction_bid) { build(:auction_bid, status: status) }

        it 'returns false' do
          expect(auction_bid).not_to be_editable
        end
      end
    end
  end

  describe '#lock_player_bids!' do
    it 'locks player bids' do
      auction_bid.lock_player_bids!

      expect(auction_bid).to be_player_bids_locked
    end
  end

  describe 'draft bid (without auction_round)' do
    it 'is valid without auction_round' do
      bid = build(:auction_bid, auction_round: nil)
      expect(bid).to be_valid
    end

    it 'can be created without auction_round' do
      expect { create(:auction_bid, auction_round: nil) }.not_to raise_error
    end
  end
end

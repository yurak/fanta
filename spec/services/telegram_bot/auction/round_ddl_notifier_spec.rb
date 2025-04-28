RSpec.describe TelegramBot::Auction::RoundDdlNotifier do
  describe '#call' do
    subject(:notifier) { described_class.new(auction) }

    let(:auction) { create(:auction) }

    context 'when auction is nil' do
      let(:auction) { nil }

      it { expect(notifier.call).to be(false) }
    end

    context 'when auction without active auction_round' do
      it { expect(notifier.call).to be(false) }
    end

    context 'when auction with initial bids' do
      let(:auction) { create(:auction) }

      before do
        create(:auction_bid, :with_empty_player_bids, auction_round: create(:auction_round, auction: auction))
      end

      it 'calls Sender service' do
        allow(TelegramBot::Sender).to receive(:call).and_return(true)

        expect(notifier.call).to be(true)
      end
    end
  end
end

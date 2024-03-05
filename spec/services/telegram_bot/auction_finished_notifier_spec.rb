RSpec.describe TelegramBot::AuctionFinishedNotifier do
  describe '#call' do
    subject(:notifier) { described_class.new(auction) }

    let(:auction) { create(:auction) }

    context 'when auction is nil' do
      let(:auction) { nil }

      it { expect(notifier.call).to be(false) }
    end

    context 'when auction league without teams' do
      it { expect(notifier.call).to be(false) }
    end

    context 'when auction league with teams' do
      let(:auction) { create(:auction, league: create(:league, :with_five_teams)) }

      it 'calls Sender service' do
        allow(TelegramBot::Sender).to receive(:call).and_return(true)

        expect(notifier.call).to be(true)
      end
    end
  end
end

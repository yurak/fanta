RSpec.describe TelegramBot::PlayerSoldNotifier do
  describe '#call' do
    subject(:notifier) { described_class.new(player, team) }

    let(:player) { create(:player) }
    let(:team) { create(:team) }

    context 'when player is nil' do
      let(:player) { nil }

      it { expect(notifier.call).to be(false) }
    end

    context 'when team is nil' do
      let(:team) { nil }

      it { expect(notifier.call).to be(false) }
    end

    context 'with valid params' do
      it 'calls Sender service' do
        allow(TelegramBot::Sender).to receive(:call).and_return(true)

        expect(notifier.call).to be(true)
      end
    end
  end
end

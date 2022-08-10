RSpec.describe TelegramBot::OpenedTourNotifier do
  describe '#call' do
    subject(:notifier) { described_class.new(tour) }

    let(:tour) { create(:tour) }

    context 'when tour nil' do
      let(:tour) { nil }

      it { expect(notifier.call).to be(false) }
    end

    context 'when tour without teams' do
      it { expect(notifier.call).to be(false) }
    end

    context 'when tour with teams' do
      let(:tour) { create(:tour, league: create(:league, :with_five_teams)) }

      it 'calls Sender service' do
        allow(TelegramBot::Sender).to receive(:call).and_return(true)

        expect(notifier.call).to be(true)
      end
    end
  end
end

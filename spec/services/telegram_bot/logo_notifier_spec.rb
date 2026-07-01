RSpec.describe TelegramBot::LogoNotifier do
  describe '#call' do
    subject(:service_call) { described_class.new(user_logo).call }

    let(:user) { create(:user, locale: :ua) }
    let(:user_logo) { create(:user_logo, user: user, status: :approved) }

    before do
      allow(I18n).to receive(:t).and_return('translated message')
      allow(TelegramBot::Sender).to receive(:call)
    end

    it 'translates the approved message in the user locale' do
      service_call
      expect(I18n).to have_received(:t).with('telegram.notifier.logo.approved', locale: :ua)
    end

    it 'sends the message to the logo owner' do
      service_call
      expect(TelegramBot::Sender).to have_received(:call).with(user, 'translated message')
    end

    it 'returns true' do
      expect(service_call).to be(true)
    end

    context 'when the logo is rejected' do
      let(:user_logo) { create(:user_logo, user: user, status: :rejected) }

      it 'translates the rejected message' do
        service_call
        expect(I18n).to have_received(:t).with('telegram.notifier.logo.rejected', locale: :ua)
      end
    end
  end
end

RSpec.describe TelegramBot::Sender do
  describe '#call' do
    subject(:sender) { described_class.new(user, message) }

    let(:user) { create(:user) }
    let(:message) { FFaker::Lorem.phrase }

    context 'when user without profile' do
      it { expect(sender.call).to be(false) }
    end

    context 'when user profile with disabled bot notifications' do
      let(:user) { create(:user, :with_profile) }

      it { expect(sender.call).to be(false) }
    end

    context 'when user profile with enabled bot notifications' do
      let(:user) { create(:user, user_profile: create(:user_profile, bot_enabled: true)) }
      let(:telegram_client) { instance_double(Telegram::Bot::Client) }
      let(:telegram_double) { double }

      it 'calls Telegram service' do
        allow(Telegram).to receive(:bots).and_return(telegram_double)
        allow(telegram_double).to receive(:[]).and_return(telegram_client)
        allow(telegram_client).to receive(:send_message).and_return({ 'ok' => true })

        expect(sender.call).to eq({ 'ok' => true })
      end
    end

    context 'when user profile with enabled bot notifications and Telegram raise Forbidden error' do
      let(:user) { create(:user, user_profile: create(:user_profile, bot_enabled: true)) }
      let(:telegram_client) { instance_double(Telegram::Bot::Client) }
      let(:telegram_double) { double }

      it 'returns false' do
        allow(Telegram).to receive(:bots).and_return(telegram_double)
        allow(telegram_double).to receive(:[]).and_return(telegram_client)
        allow(telegram_client).to receive(:send_message).and_raise(Telegram::Bot::Forbidden)

        expect(sender.call).to be(false)
      end
    end
  end
end

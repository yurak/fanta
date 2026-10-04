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

        expect(sender.call).to be(true)
      end
    end

    context 'with a parse mode' do
      subject(:sender) { described_class.new(user, message, parse_mode: 'HTML', disable_web_page_preview: true) }

      let(:user) { create(:user, user_profile: create(:user_profile, bot_enabled: true)) }
      let(:telegram_client) { instance_double(Telegram::Bot::Client) }
      let(:telegram_double) { double }

      before do
        allow(Telegram).to receive(:bots).and_return(telegram_double)
        allow(telegram_double).to receive(:[]).and_return(telegram_client)
        allow(telegram_client).to receive(:send_message).and_return({ 'ok' => true })
      end

      it 'forwards it to Telegram' do
        sender.call

        expect(telegram_client).to have_received(:send_message)
          .with(hash_including(parse_mode: 'HTML', disable_web_page_preview: true))
      end
    end

    context 'without a parse mode' do
      let(:user) { create(:user, user_profile: create(:user_profile, bot_enabled: true)) }
      let(:telegram_client) { instance_double(Telegram::Bot::Client) }
      let(:telegram_double) { double }

      before do
        allow(Telegram).to receive(:bots).and_return(telegram_double)
        allow(telegram_double).to receive(:[]).and_return(telegram_client)
        allow(telegram_client).to receive(:send_message).and_return({ 'ok' => true })
      end

      # Plain text is the default: an unescaped `&` in a team name must not reach a parser.
      it 'leaves the message as plain text' do
        sender.call

        expect(telegram_client).to have_received(:send_message).with(hash_excluding(:parse_mode))
      end
    end

    context 'when user profile with enabled bot notifications and Telegram raise Forbidden error' do
      let(:user) { create(:user, user_profile: create(:user_profile, bot_enabled: true)) }
      let(:telegram_client) { instance_double(Telegram::Bot::Client) }
      let(:telegram_double) { double }

      before do
        allow(Telegram).to receive(:bots).and_return(telegram_double)
        allow(telegram_double).to receive(:[]).and_return(telegram_client)
        allow(telegram_client).to receive(:send_message).and_raise(Telegram::Bot::Forbidden)
        allow(Rollbar).to receive(:error)
      end

      it 'returns false' do
        expect(sender.call).to be(false)
      end

      # A blocked bot is ordinary user behaviour, so it is recorded on the profile, not in Rollbar.
      it 'stops trying to reach that chat' do
        expect { sender.call }.to change { user.user_profile.reload.bot_enabled }.from(true).to(false)
      end

      it 'does not report it as an error' do
        sender.call

        expect(Rollbar).not_to have_received(:error)
      end
    end

    context 'when Telegram rate limits the bot' do
      subject(:sender) { described_class.new(user, message) }

      let(:user) { create(:user, user_profile: create(:user_profile, bot_enabled: true)) }
      let(:telegram_client) { instance_double(Telegram::Bot::Client) }
      let(:telegram_double) { double }
      let(:rate_limit) { Telegram::Bot::Error.new('Too Many Requests: retry after 2') }

      before do
        allow(Telegram).to receive(:bots).and_return(telegram_double)
        allow(telegram_double).to receive(:[]).and_return(telegram_client)
        allow(Rollbar).to receive(:error)
        allow(Kernel).to receive(:sleep)
      end

      def stub_limit_then_success
        attempts = 0
        allow(telegram_client).to receive(:send_message) do
          attempts += 1
          raise rate_limit if attempts == 1

          { 'ok' => true }
        end
      end

      # A 429 used to be swallowed like any other error, and that recipient silently lost the message.
      it 'retries and delivers' do
        stub_limit_then_success

        expect(sender.call).to be(true)
      end

      it 'waits for as long as Telegram asked' do
        stub_limit_then_success
        sender.call

        expect(Kernel).to have_received(:sleep).with(2)
      end

      context 'when the limit does not clear' do
        before { allow(telegram_client).to receive(:send_message).and_raise(rate_limit) }

        it 'gives up' do
          expect(sender.call).to be(false)
        end

        it 'reports it' do
          sender.call

          expect(Rollbar).to have_received(:error)
        end
      end

      # A wait that long means the bot is flooding, and the broadcast must not stall on one chat.
      context 'when the requested wait is excessive' do
        before do
          allow(telegram_client).to receive(:send_message)
            .and_raise(Telegram::Bot::Error.new('Too Many Requests: retry after 300'))
        end

        it 'gives up at once' do
          expect(sender.call).to be(false)
        end

        it 'does not wait' do
          sender.call

          expect(Kernel).not_to have_received(:sleep)
        end
      end
    end

    context 'when Telegram refuses the message itself' do
      let(:user) { create(:user, user_profile: create(:user_profile, bot_enabled: true)) }
      let(:telegram_client) { instance_double(Telegram::Bot::Client) }
      let(:telegram_double) { double }

      before do
        allow(Telegram).to receive(:bots).and_return(telegram_double)
        allow(telegram_double).to receive(:[]).and_return(telegram_client)
        allow(telegram_client).to receive(:send_message).and_raise(Telegram::Bot::Error, 'Bad Request')
        allow(Rollbar).to receive(:error)
      end

      # Every delivery failure used to be indistinguishable from a successful send.
      it 'reports the failure' do
        sender.call

        expect(Rollbar).to have_received(:error).with(
          instance_of(Telegram::Bot::Error), hash_including(user_id: user.id)
        )
      end

      it 'keeps the bot enabled' do
        expect { sender.call }.not_to(change { user.user_profile.reload.bot_enabled })
      end
    end
  end
end

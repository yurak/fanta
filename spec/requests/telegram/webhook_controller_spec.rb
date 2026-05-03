RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#start!' do
    subject(:command) { -> { dispatch_command :start } }

    it 'respond with message' do
      expect(command).to respond_with_message(/Welcome to MantraFootball!/)
    end

    it 'saves a TgMessage record' do
      expect do
        dispatch(message: { from: from, chat: chat, text: '/start' }, update_id: 1)
      end.to change(TgMessage, :count).by(1)
    end

    context 'with a valid connect token (Flow 2: site → bot)' do
      let!(:profile) { create(:user_profile, tg_connect_token: 'valid_token', tg_connect_expires_at: 1.hour.from_now) }

      it 'responds with connected message' do
        expect(-> { dispatch_command :start, 'valid_token' })
          .to respond_with_message(/successfully connected/)
      end

      it 'sets tg_chat_id on the user profile' do
        dispatch_command :start, 'valid_token'
        expect(profile.reload.tg_chat_id).to eq(from_id)
      end

      it 'enables bot on the user profile' do
        dispatch_command :start, 'valid_token'
        expect(profile.reload.bot_enabled).to be(true)
      end

      it 'clears the connect token' do
        dispatch_command :start, 'valid_token'
        expect(profile.reload.tg_connect_token).to be_nil
      end
    end

    context 'with a token but nil tg_connect_expires_at' do
      before { create(:user_profile, tg_connect_token: 'nil_expires_token', tg_connect_expires_at: nil) }

      it 'responds with connect_failed message' do
        expect(-> { dispatch_command :start, 'nil_expires_token' })
          .to respond_with_message(/expired or is invalid/)
      end
    end

    context 'with an expired connect token' do
      before { create(:user_profile, tg_connect_token: 'expired_token', tg_connect_expires_at: 1.hour.ago) }

      it 'responds with connect_failed message' do
        expect(-> { dispatch_command :start, 'expired_token' })
          .to respond_with_message(/expired or is invalid/)
      end
    end

    context 'with an unknown connect token' do
      it 'responds with connect_failed message' do
        expect(-> { dispatch_command :start, 'unknown_token' })
          .to respond_with_message(/expired or is invalid/)
      end
    end
  end

  describe '#help!' do
    subject(:command) { -> { dispatch_command :help } }

    it 'respond with message' do
      expect(command).to respond_with_message(/Available commands:/)
    end
  end

  describe '#register!' do
    subject(:command) { -> { dispatch_command :register } }

    it 'respond with message' do
      expect(command).to respond_with_message('Please enter the email address you will use for the game')
    end
  end

  describe '#learn_more!' do
    subject(:command) { -> { dispatch_command :learn_more } }

    it 'respond with message' do
      expect(command).to respond_with_message('You can read more about our game on our website using the link or in the attached documents')
    end
  end

  describe '#contacts!' do
    subject(:command) { -> { dispatch_command :contacts } }

    it 'respond with message' do
      expect(command).to respond_with_message('Message @mantra_help if you have any questions')
    end
  end

  context 'when unsupported command' do
    subject(:command) { -> { dispatch_command :makeMeGreatBot } }

    it 'respond with message' do
      expect(command).to respond_with_message('Can not perform makeMeGreatBot command')
    end
  end

  describe '#callback_query' do
    context "when data is 'register'" do
      subject(:call) do
        -> { dispatch callback_query: { id: 11, from: from, message: { message_id: 22, chat: chat, text: '' }, data: 'register' } }
      end

      it 'responds with register message' do
        expect(call).to respond_with_message('Please enter the email address you will use for the game')
      end
    end

    context "when data is 'learn_more'" do
      subject(:call) do
        -> { dispatch callback_query: { id: 11, from: from, message: { message_id: 22, chat: chat, text: '' }, data: 'learn_more' } }
      end

      it 'responds with learn_more message' do
        expect(call).to respond_with_message('You can read more about our game on our website using the link or in the attached documents')
      end
    end
  end

  describe '#check_email' do
    before { dispatch_command :register }

    context 'when email belongs to an existing user' do
      before { create(:user, email: 'test@example.com') }

      it 'responds with email_exist message' do
        expect(-> { dispatch_message 'test@example.com' })
          .to respond_with_message(/already in use/)
      end
    end

    context 'when tg_chat_id is already registered' do
      before { create(:user_profile, tg_chat_id: from_id) }

      it 'responds with chat_exist message' do
        expect(-> { dispatch_message 'unknown@example.com' })
          .to respond_with_message(/already connected/)
      end
    end

    context 'when email is new and no profile exists' do
      it 'responds with success message' do
        expect(-> { dispatch_message 'newuser@example.com' })
          .to respond_with_message('Please continue to register on the website')
      end
    end
  end

  describe '#action_missing' do
    context 'when action type is command' do
      it 'responds with action_missing message' do
        expect(-> { dispatch_command :unknownCmd })
          .to respond_with_message(/Can not perform unknownCmd/)
      end
    end

    context 'when action type is message (plain text)' do
      it 'does not respond' do
        expect(-> { dispatch_message 'hello' }).not_to respond_with_message(/.+/)
      end
    end
  end

  describe 'locale detection' do
    context "when language_code is 'uk'" do
      let(:from) { { id: from_id, language_code: 'uk' } }

      it 'responds in Ukrainian' do
        expect(-> { dispatch_command :help }).to respond_with_message(/Доступні команди/)
      end
    end

    context "when language_code is not 'uk'" do
      it 'responds in English' do
        expect(-> { dispatch_command :help }).to respond_with_message(/Available commands:/)
      end
    end
  end
end

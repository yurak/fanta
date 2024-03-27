RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe '#start!' do
    subject(:command) { -> { dispatch_command :start } }

    it 'respond with message' do
      expect(command).to respond_with_message(/Welcome to MantraFootball!/)
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
end

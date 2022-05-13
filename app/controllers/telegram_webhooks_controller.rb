class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext

  def start!(*)
    respond_with :message, text: 'start text'
  end

  def help!(*)
    respond_with :message, text: 'help text'
  end

  def line_up!(*)
    respond_with :message, text: 'lienup'
  end

  def message(message)
    respond_with :message, text: message['text']
  end
end

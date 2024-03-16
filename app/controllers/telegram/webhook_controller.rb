module Telegram
  class WebhookController < Telegram::Bot::UpdatesController

    include Telegram::Bot::UpdatesController::MessageContext

    def start!(*)
      respond_with :message, text: 'started'
    end

    def start!
      puts 'starting'

      respond_with :message, text: 'started'
    end

    def message(message)
      respond_with :message, text: "you are welcome #{message['from']['username']}"
    end
  end
end

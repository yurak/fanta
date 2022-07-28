module TelegramBot
  class Sender < ApplicationService
    def initialize(user, message)
      @message = message
      @user = user
    end

    def call
      return unless @user.user_profile&.bot_enabled

      begin
        Telegram.bots[:mantra_prod].send_message(chat_id: @user.user_profile.tg_chat_id, text: @message)
      rescue Telegram::Bot::Forbidden => _e
        # TODO: log error
      end
    end
  end
end

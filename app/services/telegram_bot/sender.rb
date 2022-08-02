module TelegramBot
  class Sender < ApplicationService
    def initialize(user, message)
      @message = message
      @user_profile = user.user_profile
    end

    def call
      return unless @user_profile
      return unless @user_profile.bot_enabled

      begin
        Telegram.bots[:mantra_prod].send_message(chat_id: @user_profile.tg_chat_id, text: @message)
      rescue Telegram::Bot::Forbidden => _e
        # TODO: log error
      end
    end
  end
end

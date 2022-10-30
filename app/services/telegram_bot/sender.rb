module TelegramBot
  class Sender < ApplicationService
    def initialize(user, message)
      @message = message
      @user_profile = user.user_profile
    end

    def call
      return false unless @user_profile
      return false unless @user_profile.bot_enabled

      begin
        Telegram.bots[:mantra_prod].send_message(chat_id: @user_profile.tg_chat_id, text: @message)
        true
      rescue Telegram::Bot::Error => _e
        # TODO: log error
        false
      end
    end
  end
end

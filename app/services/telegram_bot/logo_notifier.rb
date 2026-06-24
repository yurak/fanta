module TelegramBot
  class LogoNotifier < ApplicationService
    attr_reader :user_logo

    def initialize(user_logo)
      @user_logo = user_logo
    end

    def call
      user = user_logo.user
      return false unless user

      TelegramBot::Sender.call(user, message(user))
      true
    end

    private

    def message(user)
      I18n.t("telegram.notifier.logo.#{user_logo.status}", locale: user.locale.to_sym)
    end
  end
end

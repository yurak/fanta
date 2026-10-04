module TelegramBot
  class LogoNotifier < ApplicationService
    include TelegramBot::HtmlMessage
    include TelegramBot::Recipient

    attr_reader :user_logo

    def initialize(user_logo)
      @user_logo = user_logo
    end

    def call
      return false unless user

      send_html(user, message)
      true
    end

    private

    def user
      @user ||= user_logo.user
    end

    def message
      html_message("telegram.notifier.logo.#{user_logo.status}",
                   locale: locale,
                   url: Rails.application.routes.url_helpers.user_url(user))
    end
  end
end

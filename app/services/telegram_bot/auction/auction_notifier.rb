module TelegramBot
  module Auction
    class AuctionNotifier < ApplicationService
      include TelegramBot::HtmlMessage
      include TelegramBot::Recipient

      attr_reader :notification

      def initialize(notification)
        @notification = notification
      end

      def call
        return false unless notifiable
        return false unless team
        return false unless user

        send_html(user, message)
        true
      end

      private

      def notifiable
        @notifiable ||= notification.notifiable
      end

      def team
        @team ||= notification.team
      end

      def user
        @user ||= team.user
      end

      def league
        @league ||= notifiable&.league
      end

      def message
        html_message(
          'telegram.notifier.auction.default',
          locale: locale,
          icon: league.tournament.icon,
          team_name: team.human_name,
          code: league.tournament.code
        )
      end
    end
  end
end

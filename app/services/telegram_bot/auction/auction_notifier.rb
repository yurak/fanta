module TelegramBot
  module Auction
    class AuctionNotifier < ApplicationService
      attr_reader :notification

      def initialize(notification)
        @notification = notification
      end

      def call
        return false unless notifiable
        return false unless team
        return false unless user

        TelegramBot::Sender.call(user, message)
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
        I18n.t(
          'telegram.notifier.auction.default',
          locale: locale,
          icon: league.tournament.icon,
          team_name: team.human_name,
          code: league.tournament.code
        )
      end

      def locale
        user.locale&.to_sym || :en
      end

      def time_zone
        user.time_zone || User::DEFAULT_TIME_ZONE
      end
    end
  end
end

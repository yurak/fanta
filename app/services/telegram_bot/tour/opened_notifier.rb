module TelegramBot
  module Tour
    class OpenedNotifier < ApplicationService
      include TelegramBot::HtmlMessage
      include TelegramBot::Recipient

      attr_reader :notification

      def initialize(notification)
        @notification = notification
      end

      def call
        return false unless tour
        return false unless league
        return false unless team
        return false unless user

        send_html(user, message)
        true
      end

      private

      def tour
        @tour ||= notification.notifiable
      end

      def league
        @league ||= tour&.league
      end

      def team
        @team ||= notification.team
      end

      def user
        @user ||= team.user
      end

      def message
        html_message(
          'telegram.notifier.tour.opened',
          locale: locale,
          icon: league.tournament.icon,
          number: tour.number,
          league_name: league.name,
          team_name: team.human_name,
          url: Rails.application.routes.url_helpers.tour_url(tour),
          deadline: deadline,
          time_zone: time_zone,
          code: league.tournament.code
        )
      end

      def deadline
        user.local_time(tour.tournament_round.deadline, '%^a, %^b %e, %H:%M')
      end
    end
  end
end

module TelegramBot
  module Tour
    class OpenedNotifier < ApplicationService
      attr_reader :notification

      def initialize(notification)
        @notification = notification
      end

      def call
        return false unless tour
        return false unless league
        return false unless team
        return false unless user

        TelegramBot::Sender.call(user, message)
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
        I18n.t(
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

      def locale
        user.locale&.to_sym || :en
      end

      def deadline
        user.local_time(tour.tournament_round.deadline, '%^a, %^b %e, %H:%M')
      end

      def time_zone
        user.time_zone || User::DEFAULT_TIME_ZONE
      end
    end
  end
end

module TelegramBot
  module Tour
    class OpenedNotifier < ApplicationService
      attr_reader :tour

      def initialize(tour)
        @tour = tour
      end

      def call
        return false unless league
        return false if league.teams.empty?

        league.teams.each do |team|
          TelegramBot::Sender.call(team.user, message(team))
        end
        true
      end

      private

      def message(team)
        I18n.t(
          'telegram.notifier.tour.opened',
          locale: locale(team),
          icon: league.tournament.icon,
          number: tour.number,
          league_name: league.name,
          team_name: team.human_name,
          url: Rails.application.routes.url_helpers.tour_url(tour),
          deadline: tour.tournament_round.deadline&.strftime('%^a, %^b %e, %H:%M'),
          code: league.tournament.code
        )
      end

      def league
        @league ||= @tour&.league
      end

      def locale(team)
        return :en unless team.user

        team.user.locale.to_sym
      end
    end
  end
end

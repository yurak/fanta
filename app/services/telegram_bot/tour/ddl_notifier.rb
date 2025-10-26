module TelegramBot
  module Tour
    class DdlNotifier < OpenedNotifier
      def call
        return false unless tour

        tour.teams.each do |team|
          next if team.lineups&.find_by(tour: tour)

          TelegramBot::Sender.call(team.user, message(team))
        end
        true
      end

      private

      def message(team)
        I18n.t(
          'telegram.notifier.tour.ddl',
          locale: locale(team),
          icon: league.tournament.icon,
          number: tour.number,
          deadline: deadline(team),
          time_zone: time_zone(team),
          url: Rails.application.routes.url_helpers.tour_url(tour),
          code: league.tournament.code
        )
      end

      def deadline(team)
        team.user&.local_time(tour.tournament_round.deadline, '%H:%M')
      end
    end
  end
end

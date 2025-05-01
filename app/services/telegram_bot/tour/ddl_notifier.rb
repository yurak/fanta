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
          deadline: tour.tournament_round.deadline&.strftime('%H:%M'),
          url: Rails.application.routes.url_helpers.tour_url(tour),
          code: league.tournament.code
        )
      end
    end
  end
end

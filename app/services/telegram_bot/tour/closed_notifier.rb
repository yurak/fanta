module TelegramBot
  module Tour
    class ClosedNotifier < OpenedNotifier
      private

      def message(team)
        I18n.t(
          'telegram.notifier.tour.closed',
          locale: locale(team),
          icon: league.tournament.icon,
          number: tour.number,
          league_name: league.name,
          url: Rails.application.routes.url_helpers.tour_url(tour),
          code: league.tournament.code
        )
      end
    end
  end
end

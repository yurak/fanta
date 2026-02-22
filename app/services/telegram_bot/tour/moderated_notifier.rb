module TelegramBot
  module Tour
    class ModeratedNotifier < OpenedNotifier
      private

      def message
        I18n.t(
          'telegram.notifier.tour.moderated',
          locale: locale,
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

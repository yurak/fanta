module TelegramBot
  class ClosedTourNotifier < OpenedTourNotifier
    private

    def message(_)
      "#{league.tournament.icon} Round ##{@tour.number} of #{league.name} League has been closed.\n" \
        "🔴 You can check the final results here - #{Rails.application.routes.url_helpers.tour_url(@tour)}"
    end
  end
end

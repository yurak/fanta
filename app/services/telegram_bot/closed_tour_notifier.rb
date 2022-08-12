module TelegramBot
  class ClosedTourNotifier < OpenedTourNotifier
    private

    def message(_)
      "Round ##{@tour.number} of #{league.name} League has been closed. " \
        "You can check the final results here - #{Rails.application.routes.url_helpers.tour_url(@tour)}"
    end
  end
end

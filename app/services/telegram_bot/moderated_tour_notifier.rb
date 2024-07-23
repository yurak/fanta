module TelegramBot
  class ModeratedTourNotifier < OpenedTourNotifier
    private

    def message(_)
      "#{league.tournament.icon} Round ##{@tour.number} of #{league.name} League has been moderated.\n\n" \
        "All scores and bonuses have been calculated, substitutions have been made.\n" \
        "If you have remarks about bonuses - write to @mantra_help.\n\n" \
        "☑️ You can check the preliminary results here - #{Rails.application.routes.url_helpers.tour_url(@tour)}"
    end
  end
end

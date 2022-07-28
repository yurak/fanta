module TelegramBot
  class OpenedTourNotifier < ApplicationService
    def initialize(tour)
      @tour = tour
    end

    def call
      @tour.league.teams.each do |team|
        TelegramBot::Sender.call(team.user, message(team))
      end
    end

    private

    def message(team)
      "Round ##{@tour.number} of #{@tour.league.name} League has been opened. "\
      "You can set up lineup for #{team.human_name} - #{Rails.application.routes.url_helpers.tour_url(@tour)}"
    end
  end
end

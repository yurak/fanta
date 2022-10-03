module TelegramBot
  class OpenedTourNotifier < ApplicationService
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
      "#{league.tournament.icon} Round ##{@tour.number} of #{league.name} League has been opened.\n" \
        "🟢 You can set up lineup for #{team.human_name} - #{Rails.application.routes.url_helpers.tour_url(@tour)} \n" \
        "🔜 Deadline: #{@tour.tournament_round.deadline&.strftime('%^a, %^b %e, %H:%M')} (EET) 🔚"
    end

    def league
      @league ||= @tour&.league
    end
  end
end

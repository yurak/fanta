module TelegramBot
  class AuctionStartBidsNotifier < AuctionNotifier
    def call
      return false unless auction
      return false unless auction_round
      return false if league.teams.empty?

      league.teams.each do |team|
        TelegramBot::Sender.call(team.user, message(team)) if team.vacancies?
      end
      true
    end

    private

    def message(team)
      "#{league.tournament.icon} Auction round #{auction_round.number} has started in #{league.name} League.\n" \
        "🔜 Deadline: #{auction_round.deadline&.strftime('%^a, %^b %e, %H:%M')} (EET) 🔚\n\n" \
        "‼️️ You must bid on #{team.vacancies} players for #{team.human_name} - " \
        "#{Rails.application.routes.url_helpers.auction_round_path(auction_round)}"
    end

    def auction_round
      @auction_round ||= auction.auction_rounds.active.first
    end
  end
end

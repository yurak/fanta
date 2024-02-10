module TelegramBot
  class AuctionSalesOpenNotifier < AuctionNotifier
    private

    def message(team)
      "#{league.tournament.icon} Transfer window in #{league.name} League is open.\n" \
        "🔜 Deadline: #{auction.deadline&.strftime('%^a, %^b %e, %H:%M')} (EET) 🔚\n\n" \
        "‼️️ You can select up to #{auction.sales_count} players to sell from #{team.human_name} - " \
        "#{Rails.application.routes.url_helpers.edit_team_player_team_url(team, team.player_teams.first)}"
    end
  end
end

module TelegramBot
  class AuctionSalesDdlNotifier < AuctionNotifier
    private

    def message(team)
      "#{league.tournament.icon} Transfer window deadline in #{league.name} League is coming soon.\n" \
        "⚠️ Deadline today at #{auction.deadline&.strftime('%H:%M')} (EET) ⚠️\n\n" \
        "‼️️ You can select up to #{team.available_transfers} players to sell from #{team.human_name} - " \
        "#{Rails.application.routes.url_helpers.edit_team_player_team_url(team, team.player_teams.first)}"
    end
  end
end

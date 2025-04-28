module TelegramBot
  module Auction
    class SalesDdlNotifier < AuctionNotifier
      private

      def message(team)
        I18n.t(
          'telegram.notifier.auction.sales_ddl',
          locale: locale(team),
          icon: league.tournament.icon,
          league_name: league.name,
          deadline: auction.deadline&.strftime('%H:%M'),
          available_transfers: team.available_transfers,
          team_name: team.human_name,
          url: Rails.application.routes.url_helpers.edit_team_player_team_url(team, team.player_teams.first),
          code: league.tournament.code
        )
      end
    end
  end
end

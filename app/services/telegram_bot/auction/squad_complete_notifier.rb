module TelegramBot
  module Auction
    class SquadCompleteNotifier < AuctionNotifier
      private

      def message
        html_message(
          'telegram.notifier.auction.squad_complete',
          locale: locale,
          icon: league.tournament.icon,
          team_name: team.human_name,
          league_name: league.name,
          code: league.tournament.code
        )
      end
    end
  end
end

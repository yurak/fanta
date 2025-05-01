module TelegramBot
  module Auction
    class FinishedNotifier < AuctionNotifier
      private

      def message(team)
        I18n.t(
          'telegram.notifier.auction.finished',
          locale: locale(team),
          icon: league.tournament.icon,
          number: auction.number,
          league_name: league.name,
          url: Rails.application.routes.url_helpers.league_auction_transfers_url(league, auction),
          code: league.tournament.code
        )
      end
    end
  end
end

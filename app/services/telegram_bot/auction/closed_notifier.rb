module TelegramBot
  module Auction
    class ClosedNotifier < AuctionNotifier
      private

      def message
        I18n.t(
          'telegram.notifier.auction.closed',
          locale: locale,
          icon: league.tournament.icon,
          number: notifiable.number,
          league_name: league.name,
          url: Rails.application.routes.url_helpers.league_auction_url(league, notifiable),
          code: league.tournament.code
        )
      end
    end
  end
end

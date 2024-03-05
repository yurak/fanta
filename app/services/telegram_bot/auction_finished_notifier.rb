module TelegramBot
  class AuctionFinishedNotifier < AuctionNotifier
    private

    def message(_team)
      "#{league.tournament.icon} Auction ##{auction.number} in #{league.name} league has been closed.\n" \
        '🏁️️ You can view all transfers of the auction at the link - ' \
        "#{Rails.application.routes.url_helpers.league_auction_transfers_url(league, auction)}"
    end
  end
end

module TelegramBot
  module Auction
    class SalesDdlNotifier < AuctionNotifier
      private

      def message
        I18n.t(
          'telegram.notifier.auction.sales_ddl',
          locale: locale,
          icon: league.tournament.icon,
          league_name: league.name,
          deadline: deadline,
          time_zone: time_zone,
          available_transfers: team.available_transfers,
          team_name: team.human_name,
          url: Rails.application.routes.url_helpers.drops_league_auction_url(league, notifiable),
          code: league.tournament.code
        )
      end

      def deadline
        user.local_time(notifiable.deadline, '%H:%M')
      end
    end
  end
end

module TelegramBot
  module Auction
    class StartBidsNotifier < AuctionNotifier
      private

      def message
        I18n.t(
          'telegram.notifier.auction.start_offers',
          locale: locale,
          icon: league.tournament.icon,
          number: notifiable.number,
          league_name: league.name,
          deadline: deadline,
          time_zone: time_zone,
          vacancies: notifiable.slots_number_by(team),
          team_name: team.human_name,
          url: Rails.application.routes.url_helpers.auction_round_url(notifiable),
          code: league.tournament.code
        )
      end

      def deadline
        user.local_time(notifiable.deadline, '%^a, %^b %e, %H:%M')
      end
    end
  end
end

module TelegramBot
  module Auction
    class RoundDdlNotifier < AuctionNotifier
      private

      def still_relevant?
        deadline = notifiable.deadline

        deadline.blank? || deadline.future?
      end

      def message
        html_message(
          'telegram.notifier.auction.round_ddl',
          locale: locale,
          icon: league.tournament.icon,
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
        user.local_time(notifiable.deadline, '%H:%M')
      end
    end
  end
end

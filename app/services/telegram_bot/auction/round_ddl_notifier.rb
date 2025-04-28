module TelegramBot
  module Auction
    class RoundDdlNotifier < AuctionNotifier
      def call
        return false unless auction
        return false unless auction_round

        auction_round.auction_bids.initial_ongoing.each do |auction_bid|
          TelegramBot::Sender.call(auction_bid.team.user, message(auction_bid.team))
        end
        true
      end

      private

      def message(team)
        I18n.t(
          'telegram.notifier.auction.round_ddl',
          locale: locale(team),
          icon: league.tournament.icon,
          league_name: league.name,
          deadline: auction_round.deadline&.strftime('%H:%M'),
          vacancies: team.vacancies,
          team_name: team.human_name,
          url: Rails.application.routes.url_helpers.auction_round_url(auction_round),
          code: league.tournament.code
        )
      end

      def auction_round
        @auction_round ||= auction.auction_rounds.active.first
      end
    end
  end
end

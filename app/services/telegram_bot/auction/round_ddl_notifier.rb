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
          deadline: deadline(team),
          time_zone: time_zone(team),
          vacancies: auction_round.slots_number_by(team),
          team_name: team.human_name,
          url: Rails.application.routes.url_helpers.auction_round_url(auction_round),
          code: league.tournament.code
        )
      end

      def auction_round
        @auction_round ||= auction.auction_rounds.active.first
      end

      def deadline(team)
        team.user&.local_time(auction_round.deadline, '%H:%M')
      end
    end
  end
end

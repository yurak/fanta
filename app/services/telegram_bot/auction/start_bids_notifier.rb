module TelegramBot
  module Auction
    class StartBidsNotifier < AuctionNotifier
      def call
        return false unless auction
        return false unless auction_round
        return false if league.teams.empty?

        league.teams.each do |team|
          TelegramBot::Sender.call(team.user, message(team)) if team.vacancies?
        end
        true
      end

      private

      def message(team)
        I18n.t(
          'telegram.notifier.auction.start_bids',
          locale: locale(team),
          icon: league.tournament.icon,
          number: auction_round.number,
          league_name: league.name,
          deadline: auction_round.deadline&.strftime('%^a, %^b %e, %H:%M'),
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

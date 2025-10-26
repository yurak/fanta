module TelegramBot
  module Auction
    class AuctionNotifier < ApplicationService
      attr_reader :auction

      def initialize(auction)
        @auction = auction
      end

      def call
        return false unless auction
        return false if league.teams.empty?

        league.teams.each do |team|
          TelegramBot::Sender.call(team.user, message(team))
        end
        true
      end

      private

      def message(team)
        I18n.t(
          'telegram.notifier.auction.default',
          locale: locale(team),
          icon: league.tournament.icon,
          team_name: team.human_name,
          code: league.tournament.code
        )
      end

      def league
        @league ||= auction&.league
      end

      def locale(team)
        return :en unless team.user

        team.user.locale.to_sym
      end

      def time_zone(team)
        team.user&.time_zone || User::DEFAULT_TIME_ZONE
      end
    end
  end
end

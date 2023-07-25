module TelegramBot
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
      "#{league.tournament.icon} Auction message to #{team.human_name}"
    end

    def league
      @league ||= auction&.league
    end
  end
end

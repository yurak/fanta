module TournamentRounds
  class BundesParser < ApplicationService
    BUNDES_DATA_URL = 'https://www.fotmob.com/leagues?id=54&tab=matches&type=league'.freeze

    attr_reader :tournament_round

    def initialize(tournament_round:)
      @tournament_round = tournament_round
    end

    def call
      request.code == 200 ? all_matches_data[tournament_round.number.to_s] : []
    end

    private

    def all_matches_data
      JSON.parse(request)['matchesTab']['data']['matchesCombinedByRound']
    end

    def request
      @request ||= RestClient.get(BUNDES_DATA_URL)
    end
  end
end

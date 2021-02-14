module TournamentRounds
  class FotmobParser < ApplicationService
    attr_reader :tournament_round, :tournament_url

    def initialize(tournament_round:, tournament_url:)
      @tournament_round = tournament_round
      @tournament_url = tournament_url
    end

    def call
      request.code == 200 ? all_matches_data[tournament_round.number.to_s] : []
    end

    private

    def all_matches_data
      JSON.parse(request)['matchesTab']['data']['matchesCombinedByRound']
    end

    def request
      @request ||= RestClient.get(tournament_url)
    end
  end
end

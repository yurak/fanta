module TournamentRounds
  class FotmobParser < ApplicationService
    attr_reader :tournament_round, :tournament_url

    def initialize(tournament_url:, tournament_round: nil)
      @tournament_round = tournament_round
      @tournament_url = tournament_url
    end

    def call
      return [] unless tournament_url
      return [] unless request.code == 200

      tournament_round&.number ? all_matches_data[tournament_round.number.to_s] : all_matches_data
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

module TournamentRounds
  class EplEventsParser < ApplicationService
    EPL_EVENTS_URL = 'http://132.145.254.115:8080/scrapper/mantra/rounds/facts?round='.freeze

    attr_reader :tournament_round

    def initialize(tournament_round: nil)
      @tournament_round = tournament_round
    end

    def call
      request.code == 200 ? JSON.parse(request) : []
    end

    private

    def request
      @request ||= RestClient.get(tournament_round_url)
    end

    def tournament_round_url
      "#{EPL_EVENTS_URL}#{tournament_round.number}"
    end
  end
end

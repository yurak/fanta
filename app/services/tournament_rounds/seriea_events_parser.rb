module TournamentRounds
  class SerieaEventsParser < ApplicationService
    ROUND_URL = 'https://www.magicleghe.fco.live/it/serie-a/2021-2022/diretta-live/'.freeze

    attr_reader :tournament_round

    def initialize(tournament_round)
      @tournament_round = tournament_round
    end

    def call
      request.code == 200 ? matches_data : []
    end

    private

    def matches_data
      html_page.css('#app .giornata-matches .tab-content').children
    end

    def html_page
      @html_page ||= Nokogiri::HTML(request)
    end

    def request
      @request ||= RestClient.get(tournament_round_url)
    end

    def tournament_round_url
      "#{ROUND_URL}#{tournament_round.number}-giornata"
    end
  end
end

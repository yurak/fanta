module TournamentRounds
  class FotmobParser < ApplicationService
    LEAGUE_URL = "https://www.fotmob.com/api/leagues?id=".freeze
    attr_reader :tournament_round, :tournament

    def initialize(tournament, tournament_round = nil)
      @tournament_round = tournament_round
      @tournament = tournament
    end

    def call
      return [] unless tournament&.source_id
      return [] unless request.code == 200

      tournament_round&.number ? all_matches_data.select{ |r| r['round'] == tournament_round.number} : all_matches_data
    end

    private

    def all_matches_data
      # JSON.parse(html_page)['props']['pageProps']['matches']['data']['matchesCombinedByRound']
      JSON.parse(request)['matches']['allMatches']
    end

    # def html_page
    #   @html_page ||= Nokogiri::HTML(request).css('#__NEXT_DATA__').text
    # end

    def request
      @request ||= RestClient.get("#{LEAGUE_URL}#{tournament.source_id}")
    end
  end
end

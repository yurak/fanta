module Scores
  class Parser
    URL = 'https://www.magicleghe.fco.live/it/serie-a/2019-2020/diretta-live/'.freeze
    attr_reader :tour

    def initialize(tour: nil)
      @tour = tour
    end

    def call
      (1...all_matches_data.length).step(2).each do |index|
        match = all_matches_data[index]
        host_club = Club.find_by(name: host_name(match))
        host_players_scores(match).each do |player|
          mp = MatchPlayer.by_tour(tour.id).by_name_and_club(player_name(player).titleize, host_club.id).first
        end

        guest_club = Club.find_by(name: guest_name(match))
        guest_players_scores(match).each do |player|
          mp = MatchPlayer.by_tour(tour.id).by_name_and_club(player_name(player).titleize, host_club.id).first
        end
      end
    end

    private

    def all_matches_data
      @all_matches_data ||= html_page.css('#app .giornata-matches .tab-content').children
    end

    def player_name(player)
      player.css('.voti-last-name').children.text.rstrip
    end

    def player_score(player)
      player.css('.live-score-board-handler-vote').children.text.rstrip
    end

    def host_name(match_info)
      match_info.css('.home-team-name').children.text
    end

    def guest_name(match_info)
      match_info.css('.away-team-name').children.text
    end

    def host_players_scores(match_info)
      match_info.css('.home-team-votes table tbody tr')
    end

    def guest_players_scores(match_info)
      match_info.css('.away-team-votes table tbody tr')
    end

    def html_page
      @html_page ||= Nokogiri::HTML(request)
    end

    def request
      RestClient.get(tour_url)
    end

    def tour_url
      "#{URL}#{real_tour_number}-giornata"
    end

    def real_tour_number
      tour.number+2
    end
  end
end

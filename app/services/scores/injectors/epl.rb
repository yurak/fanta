module Scores
  module Injectors
    class Epl < ApplicationService
      URL = 'http://132.145.254.115:8080/scrapper/mantra/rounds?round='.freeze
      attr_reader :tour

      def initialize(tour: nil)
        @tour = tour
      end

      def call
        tour.match_players.each do |mp|
          player_data = scores_arr.detect { |pl| pl['name'].mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').downcase.to_s == mp.player.pseudo_name.downcase }
          mp.update(score: player_data['stat'].to_f) if player_data && player_data['stat'].to_f.positive?
        end
      end

      private

      def scores_arr
        @scores_arr ||= JSON.parse(request)
      end

      def request
        RestClient.get(tour_url)
      end

      def tour_url
        "#{URL}#{tour.real_number}"
      end
    end
  end
end

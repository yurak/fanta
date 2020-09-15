module Scores
  module Injectors
    class Epl < ApplicationService
      EPL_SCORES_URL = 'http://132.145.254.115:8080/scrapper/mantra/rounds?round='.freeze
      attr_reader :tournament_round

      def initialize(tournament_round: nil)
        @tournament_round = tournament_round
      end

      def call
        RoundPlayer.by_tournament_round(tournament_round.id).each do |rp|
          mp_pseudo = rp.player.pseudo_name.downcase
          player_data = scores_arr.detect { |pl| pl['name'].mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').downcase.to_s == mp_pseudo }
          rp.update(score: player_data['stat'].to_f) if player_data && player_data['stat'].to_f.positive?
        end
      end

      private

      def scores_arr
        @scores_arr ||= JSON.parse(request)
      end

      def request
        RestClient.get(tournament_round_url)
      end

      def tournament_round_url
        "#{EPL_SCORES_URL}#{tournament_round.number}"
      end
    end
  end
end

module Scores
  module Injectors
    class Calcio < ApplicationService
      STATUS_FINISHED_MATCH = 'Terminata'.freeze
      attr_reader :tournament_round

      def initialize(tournament_round: nil)
        @tournament_round = tournament_round
      end

      def call
        (1...all_matches_data.length).step(2).each do |index|
          match = all_matches_data[index]
          next unless match_status(match) == STATUS_FINISHED_MATCH

          update_host_players(match)
          update_guest_players(match)
        end
      end

      private

      def update_host_players(match)
        host_club = Club.find_by(name: host_name(match))

        host_players_scores(match).reverse_each do |player|
          round_player(player, host_club.id)&.update(score: player_score(player))
        end
      end

      def update_guest_players(match)
        guest_club = Club.find_by(name: guest_name(match))

        guest_players_scores(match).reverse_each do |player|
          round_player(player, guest_club.id)&.update(score: player_score(player))
        end
      end

      def all_matches_data
        @all_matches_data ||= TournamentRounds::SerieaEventsParser.call(tournament_round: tournament_round)
      end

      def match_status(match_info)
        match_info.css('.score-container .status').children.text
      end

      def round_player(player, club_id)
        RoundPlayer.by_tournament_round(tournament_round.id).by_name_and_club(player_name(player), club_id).first
      end

      def player_name(player)
        I18n.transliterate(player.css('.voti-last-name').children.text.rstrip).downcase.titleize
      end

      def player_score(player)
        player.css('.live-score-board-handler-vote').children.text.rstrip.to_f
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
    end
  end
end

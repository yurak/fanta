module Scores
  module Injectors
    class Calcio < ApplicationService
      STATUS_FINISHED_MATCH = 'Terminata'.freeze
      attr_reader :tournament_round

      def initialize(tournament_round: nil)
        @tournament_round = tournament_round
      end

      def call
        return false unless tournament_round

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

        return unless host_club

        host_players_scores(match).reverse_each do |player|
          update_player(player, host_club.id)
        end
      end

      def update_guest_players(match)
        guest_club = Club.find_by(name: guest_name(match))

        return unless guest_club

        guest_players_scores(match).reverse_each do |player|
          update_player(player, guest_club.id)
        end
      end

      def update_player(player, club_id)
        return unless round_player(player, club_id)

        round_player(player, club_id).update(
          score: player_score(player),
          played_minutes: played_minutes(player) || 0
        )
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

      def played_minutes(player)
        value = player.css('.text-muted.fs-12').first.text.tr('(', '').tr("')", '').to_i if player.css('.text-muted.fs-12').first

        player_score(player).positive? && (value.nil? || value > 90) ? 90 : value
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

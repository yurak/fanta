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

          update_match_result(match)

          update_host_players(match)
          update_guest_players(match)
        end
      end

      private

      def update_match_result(match)
        t_match = tournament_round.tournament_matches.find_by(host_club: host_club(match), guest_club: guest_club(match))

        return unless t_match

        t_match.update(host_score: host_club_score(match), guest_score: guest_club_score(match))
      end

      def update_host_players(match)
        return unless host_club(match)

        host_players_scores(match).reverse_each do |player|
          update_player(player, host_club(match).id)
        end
      end

      def update_guest_players(match)
        return unless guest_club(match)

        guest_players_scores(match).reverse_each do |player|
          update_player(player, guest_club(match).id)
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
        @all_matches_data ||= TournamentRounds::SerieaEventsParser.call(tournament_round)
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

      def host_club(match)
        Club.find_by(name: match.css('.home-team-name').children.text)
      end

      def guest_club(match)
        Club.find_by(name: match.css('.away-team-name').children.text)
      end

      def host_club_score(match_info)
        match_info.css('.score-container .home-score').children.text
      end

      def guest_club_score(match_info)
        match_info.css('.score-container .away-score').children.text
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

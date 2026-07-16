class Player
  module SeasonStats # rubocop:disable Metrics/ModuleLength
    extend ActiveSupport::Concern

    def chart_info(matches)
      bs = {}
      ts = {}
      matches.each do |rp|
        bs[rp.tournament_round.number] = rp.score.to_s
        ts[rp.tournament_round.number] = rp.result_score.to_s
      end
      [{ name: 'Total score', data: ts }, { name: 'Base score', data: bs }]
    end

    def season_matches_with_scores
      @season_matches_with_scores ||=
        round_players.with_score.includes(:tournament_round).by_tournament_round(club_tournament_season_rounds)
    end

    def season_matches
      @season_matches ||= round_players.by_tournament_round(club_tournament_season_rounds)
    end

    def season_club_matches_w_scores
      @season_club_matches_w_scores ||= round_players.with_score.by_tournament_round(season_tournament_rounds)
    end

    def season_club_in_squad
      @season_club_in_squad ||= round_players.in_squad.by_tournament_round(season_tournament_rounds)
    end

    def season_ec_matches_with_scores
      @season_ec_matches_with_scores ||=
        round_players.with_score.by_tournament_round(season_club_eurocup_rounds).order(:tournament_round_id)
    end

    def season_ec_in_squad
      @season_ec_in_squad ||= round_players.in_squad.by_tournament_round(season_club_eurocup_rounds).order(:tournament_round_id)
    end

    def season_all_matches_with_scores
      @season_all_matches_with_scores ||=
        round_players.with_score.by_tournament_round(season_all_tournam_rounds).order(:tournament_round_id)
    end

    def national_matches_with_scores
      @national_matches_with_scores ||= round_players.with_score.by_tournament_round(national_team_rounds).order(:tournament_round_id)
    end

    def national_in_squad
      @national_in_squad ||= round_players.in_squad.by_tournament_round(national_team_rounds).order(:tournament_round_id)
    end

    # In-squad round players for an arbitrary season (memoized per season id)
    def club_in_squad_for(season)
      (@club_in_squad_for ||= {})[season.id] ||=
        round_players.in_squad.by_tournament_round(club_season_rounds(season))
    end

    def ec_in_squad_for(season)
      (@ec_in_squad_for ||= {})[season.id] ||=
        round_players.in_squad.by_tournament_round(ec_season_rounds(season)).order(:tournament_round_id)
    end

    def national_in_squad_for(season)
      return RoundPlayer.none unless national_team&.tournament

      (@national_in_squad_for ||= {})[season.id] ||=
        round_players.in_squad.by_tournament_round(national_season_rounds(season)).order(:tournament_round_id)
    end

    def season_scores_count(matches = season_matches_with_scores)
      matches.size
    end

    def season_average_score(matches = season_matches_with_scores)
      return 0 if season_scores_count(matches).zero?

      (matches.map(&:score).sum / season_scores_count(matches)).round(2)
    end

    def season_average_result_score(matches = season_matches_with_scores)
      return 0 if season_scores_count(matches).zero?

      (matches.map(&:result_score).sum / season_scores_count(matches)).round(2)
    end

    def season_bonus_count(matches, bonus)
      return 0 unless matches.any?

      matches.map(&bonus.to_sym).sum.to_i
    end

    def season_cards_count(matches, card)
      return 0 unless matches.any?

      matches.where(card => true).count
    end

    def season_played_minutes(matches = season_matches_with_scores)
      return 0 unless matches.any?

      matches.map(&:played_minutes).sum
    end

    def sixty_minutes_plus(matches = season_matches_with_scores)
      matches.where('played_minutes >= ?', MatchPlayer::MIN_PLAYED_MINUTES_FOR_CS).count
    end

    def current_season
      @current_season ||= Season.last
    end

    private

    # all TournamentRound in current tournament for this season
    def club_tournament_season_rounds
      @club_tournament_season_rounds ||=
        club.tournament ? TournamentRound.by_tournament(club.tournament.id).by_season(current_season.id) : []
    end

    # all TournamentRound for this season
    def season_tournament_rounds
      @season_tournament_rounds ||=
        TournamentRound.by_tournament(Tournament.with_clubs).by_season(current_season.id).order(deadline: :desc)
    end

    def season_club_eurocup_rounds
      @season_club_eurocup_rounds ||=
        TournamentRound.by_tournament(Tournament.with_ec_clubs).by_season(current_season.id)
    end

    def season_all_tournam_rounds
      season_tournament_rounds + season_club_eurocup_rounds
    end

    def national_team_rounds
      return [] unless national_team&.tournament

      @national_team_rounds ||= national_team.tournament.tournament_rounds.by_season(current_season.id)
    end

    def club_season_rounds(season)
      TournamentRound.by_tournament(Tournament.with_clubs).by_season(season.id).order(deadline: :desc)
    end

    def ec_season_rounds(season)
      TournamentRound.by_tournament(Tournament.with_ec_clubs).by_season(season.id)
    end

    def national_season_rounds(season)
      national_team.tournament.tournament_rounds.by_season(season.id)
    end
  end
end

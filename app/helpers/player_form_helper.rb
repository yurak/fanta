module PlayerFormHelper
  FORM_ROUNDS = 5
  FORM_FULL_MINUTES = 60
  # order shown in the hover legend that decodes the form-cell colors
  LEGEND_STATES = %w[full part bench out skipped empty].freeze

  # Last-N-rounds form for a set of players, keyed by player id. Each value is an
  # array of exactly FORM_ROUNDS cells (oldest → newest); rounds that do not exist
  # yet (early in the season) are padded on the left as { state: 'empty' }.
  # Loads every player's round data in a single query to avoid an N+1.
  def players_last_rounds_form(players, current_round, count: FORM_ROUNDS)
    return {} unless current_round && players.present?

    rounds = form_rounds(current_round, count)
    return {} if rounds.empty?

    cells = RoundPlayer.where(player_id: players.map(&:id), tournament_round_id: rounds.map(&:id))
                       .index_by { |rp| [rp.player_id, rp.tournament_round_id] }
    pad = Array.new(count - rounds.size) { { state: 'empty' } }
    played = club_rounds_played(rounds)

    players.to_h { |player| [player.id, player_form_row(player, rounds, cells, pad, played)] }
  end

  def player_form_row(player, rounds, cells, pad, played = nil)
    pad + rounds.map do |round|
      next { state: 'skipped' } if played && round_skipped?(player, round, played)

      player_form_cell(cells[[player.id, round.id]])
    end
  end

  def round_skipped?(player, round, played)
    played[:rounds].include?(round.id) && played[:clubs].exclude?([player.club_id, round.id])
  end

  # Only matches with a result count as "played" — a postponed/upcoming fixture keeps its
  # TournamentMatch row (scores still nil), so a club whose match slipped out of the round
  # must resolve to `skipped`, not `out` (which would wrongly blame the player).
  def club_rounds_played(rounds)
    pairs = TournamentMatch.where(tournament_round_id: rounds.map(&:id))
                           .where.not(host_score: nil).where.not(guest_score: nil)
                           .pluck(:tournament_round_id, :host_club_id, :guest_club_id)

    {
      rounds: pairs.to_set(&:first),
      clubs: pairs.flat_map { |round_id, host_id, guest_id| [[host_id, round_id], [guest_id, round_id]] }.to_set
    }
  end

  def form_rounds(current_round, count)
    TournamentRound.where(tournament_id: current_round.tournament_id, season_id: current_round.season_id)
                   .where(number: ...current_round.number)
                   .order(number: :desc).limit(count).to_a.reverse
  end

  def player_form_cell(round_player)
    return { state: 'out' } if round_player.nil? || !round_player.in_squad

    minutes = round_player.played_minutes.to_i
    return { state: 'bench' } if minutes.zero?

    { state: minutes >= FORM_FULL_MINUTES ? 'full' : 'part', score: player_form_score(round_player) }
  end

  # base rating of the round, without bonuses/maluses (final_score is the fantasy score)
  def player_form_score(round_player)
    score = round_player.score.to_f
    return nil unless score.positive?

    format('%g', score.round(1))
  end
end

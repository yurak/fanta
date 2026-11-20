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
    matches = form_round_matches(rounds)
    context = { played: club_rounds_played(matches), opponents: club_opponents(matches) }

    players.to_h { |player| [player.id, player_form_row(player, rounds, cells, pad, context)] }
  end

  def player_form_row(player, rounds, cells, pad, context = {})
    played = context[:played]

    pad + rounds.map do |round|
      cell = if played && round_skipped?(player, round, played)
               { state: 'skipped' }
             else
               player_form_cell(cells[[player.id, round.id]])
             end

      cell.merge(round: round.number, opponent: context.dig(:opponents, [player.club_id, round.id]))
    end
  end

  def round_skipped?(player, round, played)
    played[:rounds].include?(round.id) && played[:clubs].exclude?([player.club_id, round.id])
  end

  # Every fixture of the rounds on show, result or not: the opponent is worth naming in the
  # hover details even for a postponed match, while only a played one counts as `played`.
  def form_round_matches(rounds)
    TournamentMatch.where(tournament_round_id: rounds.map(&:id))
                   .pluck(:tournament_round_id, :host_club_id, :guest_club_id, :host_score, :guest_score)
  end

  # Only matches with a result count as "played" — a postponed/upcoming fixture keeps its
  # TournamentMatch row (scores still nil), so a club whose match slipped out of the round
  # must resolve to `skipped`, not `out` (which would wrongly blame the player).
  def club_rounds_played(matches)
    pairs = matches.select { |_, _, _, host_score, guest_score| host_score && guest_score }

    {
      rounds: pairs.to_set(&:first),
      clubs: pairs.flat_map { |round_id, host_id, guest_id, _, _| [[host_id, round_id], [guest_id, round_id]] }.to_set
    }
  end

  # { [club_id, round_id] => { name:, home: } } for both sides of every fixture
  def club_opponents(matches)
    clubs = Club.where(id: matches.flat_map { |_, host_id, guest_id, _, _| [host_id, guest_id] }.uniq).index_by(&:id)

    matches.each_with_object({}) do |(round_id, host_id, guest_id, _, _), map|
      map[[host_id, round_id]] = { name: clubs[guest_id]&.name, home: true }
      map[[guest_id, round_id]] = { name: clubs[host_id]&.name, home: false }
    end
  end

  def form_rounds(current_round, count)
    TournamentRound.where(tournament_id: current_round.tournament_id, season_id: current_round.season_id)
                   .where(number: ...current_round.number)
                   .order(number: :desc).limit(count).to_a.reverse
  end

  def player_form_cell(round_player)
    return { state: 'out' } if round_player.nil? || !round_player.in_squad

    minutes = round_player.played_minutes.to_i
    return { state: 'bench', minutes: 0 } if minutes.zero?

    {
      state: minutes >= FORM_FULL_MINUTES ? 'full' : 'part',
      score: player_form_score(round_player),
      final_score: player_form_number(round_player.final_score),
      minutes: minutes
    }
  end

  # base rating of the round, without bonuses/maluses (final_score is the fantasy score)
  def player_form_score(round_player)
    player_form_number(round_player.score)
  end

  def form_opponent_label(cell)
    opponent = cell[:opponent]
    return '–' unless opponent && opponent[:name]

    "(#{t(opponent[:home] ? 'lineups.home' : 'lineups.away')}) #{opponent[:name]}"
  end

  def form_minutes_label(cell)
    cell[:minutes] ? "#{cell[:minutes]}'" : '–'
  end

  def player_form_number(value)
    number = value.to_f
    return nil unless number.positive?

    format('%g', number.round(1))
  end
end

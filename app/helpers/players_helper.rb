module PlayersHelper
  def available_for_select(team)
    team.players.sort_by(&:position_sequence_number).collect do |x|
      [
        "(#{x.position_names.join('-')}) #{x.name} / #{x.club.code} / vs #{opponent_code(x, team)}", x.id
      ]
    end
  end

  def available_for_select_by_positions(team, positions: nil, real_position: nil)
    if positions
      scope = team.players.includes(:positions).where(positions: { name: positions }).sort_by(&:position_sequence_number)
    else
      scope = team.players.sort_by(&:position_sequence_number)
    end

    scope.collect do |x|
      klass = 'malus'
      if positions && real_position && !x.position_names.include?(real_position)
        klass += Scores::PositionMalus::Counter.call(real_position, x.position_names).to_s.tr('.', '')
      end

      [
        "(#{x.reload.position_names.join('-')}) #{x.name} / #{x.club.code} / vs #{opponent_code(x, team)}", x.id, { class: klass }
      ]
    end
  end

  def available_for_substitution(match_players, positions)
    available_mp = match_players.collect do |x|
      next if (x.position_names & positions).empty?

      [
        "(#{x.player.position_names.join('-')}) #{x.player.name} - #{x.score}", x.id
      ]
    end
    available_mp.compact
  end

  def opponent_code(player, team)
    player.club.opponent_by_round(team.next_round.tournament_round).code
  end
end

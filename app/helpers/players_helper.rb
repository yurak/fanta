module PlayersHelper
  def available_for_select(team)
    team.players.order_by_status.collect do |x|
      klass = x.status
      [
        "(#{x.position_names.join('-')}) #{x.name} / #{x.club.code} /", x.id, { class: klass }
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
        "(#{x.reload.position_names.join('-')}) #{x.name} / #{x.club.code} /", x.id, { class: klass }
      ]
    end
  end

  def available_for_substitution(match_players)
    match_players.collect do |x|
      [
        "(#{x.player.position_names.join('-')}) #{x.player.name} - #{x.real_position || '(reserve)'}", x.id
      ]
    end
  end
end

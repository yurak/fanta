module PlayersHelper
  def available_for_select(team)
    team.players.order_by_status.collect do |x|
      klass = x.status
      [
        "(#{x.position_names.join('-')}) #{x.name} / #{x.club.code} /", x.id, { class: klass }
      ]
    end
  end

  def available_for_select_by_positions(team, positions: nil)
    scope = if positions
              team.players.includes(:positions).where(positions: { name: positions })
            else
              team.players
            end

    scope.order_by_status.collect do |x|
      klass = x.status
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

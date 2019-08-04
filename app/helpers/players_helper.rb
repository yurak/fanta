module PlayersHelper
  def available_for_select(team)
    team.players.order_by_status.collect do |x|
      klass = x.status
      [
        "(#{x.positions.map(&:name).join('-')}) #{x.name} (#{x.status})", x.id, { class: klass}
      ]
    end
  end

  def available_for_select_by_positions(team, positions: nil)
    if positions
      scope = team.players.includes(:positions).where(positions: { name:  positions})
    else
      scope = team.players
    end

    scope.order_by_status.collect do |x|
      klass = x.status
      [
        "(#{x.positions.map(&:name).join('-')}) #{x.name} (#{x.status})", x.id, { class: klass}
      ]
    end
  end
end

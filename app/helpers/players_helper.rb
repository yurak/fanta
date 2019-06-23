module PlayersHelper
  def available_for_select(team)
    team.players.order_by_status.collect do |x|
      klass = x.status
      [
        "(#{x.positions.map(&:name).join('-')}) #{x.name} (#{x.status})", x.id, { class: klass}
      ]
    end
  end
end

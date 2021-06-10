module PlayersHelper
  def available_for_substitution(match_players, positions)
    available_mp = match_players.collect do |x|
      next if (x.position_names & positions).empty?

      [
        "(#{x.player.position_names.join('-')}) #{x.player.name} - #{x.score}", x.id
      ]
    end
    available_mp.compact
  end

  def tournament_round_players(tournament_round, real_position)
    Player.by_national_tournament_round(tournament_round).by_position(real_position&.split('/')).uniq.sort_by(&:national_team_id)
  end

  def player_by_mp(match_player)
    return unless match_player.object.round_player_id
    return unless (match_player.object.player.position_names & team_module.slots[match_player.index]&.positions).any?

    match_player.object.player
  end

  def module_link(lineup, team_module)
    if lineup.id
      edit_team_lineup_path(lineup.team, lineup, team_module_id: team_module.id)
    else
      new_team_lineup_path(lineup.team, team_module_id: team_module.id, tour_id: lineup.tour.id)
    end
  end
end

module PlayersHelper
  def available_for_substitution(match_players, positions)
    return [] unless match_players && positions

    available_mp = match_players.collect do |x|
      next if (x.position_names & positions).empty?

      [
        "(#{x.position_names.join('-')}) #{x.player.name} - #{x.score}", x.id
      ]
    end
    available_mp.compact
  end

  def available_for_select(team)
    team.players.sort_by(&:position_sequence_number)
  end

  def available_by_slot(team, slot)
    return {} unless slot

    scope = team.players.includes(:positions).where(positions: { name: slot.positions_with_malus }).sort_by(&:position_sequence_number)

    scope.group_by do |x|
      Scores::PositionMalus::Counter.call(slot.position, x.reload.position_names).to_s
    end
  end

  def tournament_round_players(tournament_round, real_position)
    # TODO: should be updated for national/eurocups tournaments
    Player.by_national_tournament_round(tournament_round).by_position(real_position&.split('/')).uniq.sort_by(&:national_team_id)
  end

  def player_by_mp(match_player, team_module)
    return unless match_player.object.round_player_id

    slot = team_module.slots[match_player.index]
    return if slot&.position && (match_player.object.player.position_names & slot.positions).blank?

    match_player.object.player
  end

  def module_link(lineup, team_module)
    if lineup.id
      edit_team_lineup_path(lineup.team, lineup, team_module_id: team_module.id)
    else
      new_team_lineup_path(lineup.team, team_module_id: team_module.id, tour_id: lineup.tour.id)
    end
  end

  def auction_step(league)
    teams = league.teams
    return 0 if teams.count.zero?

    transfers = league.transfers.count
    return teams[0].id if transfers.zero?

    teams[transfers % teams.count].id
  end
end

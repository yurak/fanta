module PlayersHelper
  def available_for_substitution(match_player, bench_players)
    return [] unless bench_players && match_player&.available_positions

    available_mp = bench_players.collect do |x|
      next if (x.position_names & match_player.available_positions).empty?

      [x, Scores::PositionMalus::Counter.call(match_player.real_position, x.position_names).to_s]
    end
    available_mp.compact
  end

  def available_for_select(team)
    team.players.sort_by(&:position_sequence_number)
  end

  def subs_string(match_player)
    "Replaced: #{match_player.main_subs.last&.out_rp&.full_name_reverse} by #{match_player.main_subs&.first&.subs_by}"
  end


  def available_by_slot(team, slot)
    return {} unless slot

    scope = team.players.includes(:positions).where(positions: { name: slot.positions_with_malus }).sort_by(&:position_sequence_number)

    scope.group_by do |x|
      Scores::PositionMalus::Counter.call(slot.position, x.reload.position_names).to_s
    end
  end

  def tournament_round_players(t_round, real_position)
    if t_round.national_matches.any?
      Player.by_national_tournament_round(t_round).by_position(real_position&.split('/')).uniq
            .sort_by(&:position_sequence_number).group_by(&:national_team).sort_by { |x, _| [x.name] }
    else
      []
    end
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

  def user_tournament_team(tournament_id)
    return false unless current_user

    @user_tournament_team ||= current_user.teams.by_tournament(tournament_id || 1).first
  end

  def current_season
    @current_season ||= Season.last
  end
end

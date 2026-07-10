module WeeklyTeamsHelper
  def weekly_team_def_bonus(team, source)
    return 0 if source.to_s == 'avg'

    scores = team.filter_map do |row|
      entry = row[:entry]
      next unless entry && (row[:slot].positions & Position::DEFENCE).any?

      entry[:round_player].score
    end
    WeeklyTeam.defence_bonus_for(scores)
  end

  def weekly_team_total(team, source)
    team.sum { |row| row[:entry]&.dig(:total) || 0 } + weekly_team_def_bonus(team, source)
  end
end

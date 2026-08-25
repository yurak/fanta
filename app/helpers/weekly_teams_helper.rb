module WeeklyTeamsHelper
  def weekly_team_def_bonus(team, source)
    return 0 if %w[avg auction].include?(source.to_s)

    scores = team.filter_map do |row|
      entry = row[:entry]
      next unless entry && row[:slot].positions.intersect?(Position::DEFENCE)

      entry[:round_player].score
    end
    DefenceBonus.for_scores(scores)
  end

  def weekly_team_total(team, source)
    team.sum { |row| row[:entry]&.dig(:total) || 0 } + weekly_team_def_bonus(team, source)
  end

  # average auction price rounded to one decimal (half-up), always with a trailing decimal:
  # 26 -> "26.0", 31.25 -> "31.3", 32.96 -> "33.0"
  def weekly_team_avg_price(value)
    return if value.nil?

    format('%.1f', value.round(1))
  end
end

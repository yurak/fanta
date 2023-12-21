class PlayerStatsSerializer < ActiveModel::Serializer
  attributes :id
  attributes :current_season_stat
  attributes :current_season_stat_eurocup
  attributes :current_season_stat_national
  attributes :round_stats
  attributes :round_stats_eurocup
  attributes :round_stats_national
  attributes :season_stats

  def current_season_stat
    PlayerCurrentSeasonStatSerializer.new(object, matches: object.season_matches_with_scores)
  end

  def current_season_stat_eurocup
    PlayerCurrentSeasonStatSerializer.new(object, matches: object.season_ec_matches_with_scores)
  end

  def current_season_stat_national
    PlayerCurrentSeasonStatSerializer.new(object, matches: object.national_matches_with_scores)
  end

  def round_stats
    object.season_matches_with_scores.reverse.map { |rp| RoundPlayerSerializer.new(rp) }
  end

  def round_stats_eurocup
    object.season_ec_matches_with_scores.reverse.map { |rp| RoundPlayerSerializer.new(rp) }
  end

  def round_stats_national
    object.national_matches_with_scores.reverse.map { |rp| RoundPlayerSerializer.new(rp) }
  end

  def season_stats
    object.player_season_stats.map { |pss| PlayerSeasonStatSerializer.new(pss) }
  end
end

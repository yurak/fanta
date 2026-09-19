class PlayerStatsSerializer < ActiveModel::Serializer
  attributes :id
  attributes :current_season_stat
  attributes :current_season_stat_eurocup
  attributes :current_season_stat_national
  attributes :round_stats
  attributes :round_stats_eurocup
  attributes :round_stats_national
  attributes :season_stats
  attributes :seasons

  def current_season_stat
    PlayerCurrentSeasonStatSerializer.new(object, matches: club_in_squad.with_score)
  end

  def current_season_stat_eurocup
    PlayerCurrentSeasonStatSerializer.new(object, matches: ec_in_squad.with_score)
  end

  def current_season_stat_national
    PlayerCurrentSeasonStatSerializer.new(object, matches: national_in_squad.with_score)
  end

  def round_stats
    club_in_squad.reverse.map { |rp| RoundPlayerSerializer.new(rp) }
  end

  def round_stats_eurocup
    ec_in_squad.reverse.map { |rp| RoundPlayerSerializer.new(rp) }
  end

  def round_stats_national
    national_in_squad.reverse.map { |rp| RoundPlayerSerializer.new(rp) }
  end

  def season_stats
    object.player_season_stats
          .sort_by { |pss| [pss.season_id.to_i, pss.created_at.to_i] }
          .reverse
          .map { |pss| PlayerSeasonStatSerializer.new(pss) }
  end

  def seasons
    Season.where(id: season_ids).order(id: :desc).map do |season|
      { id: season.id, start_year: season.start_year, end_year: season.end_year }
    end
  end

  private

  def season_ids
    from_rounds = TournamentRound.where(id: object.round_players.select(:tournament_round_id))
                                 .distinct.pluck(:season_id)

    (object.player_season_stats.map(&:season_id) + from_rounds + [Season.last&.id]).compact.uniq
  end

  def season
    @season ||= instance_options[:season] || object.current_season
  end

  def club_in_squad
    object.club_in_squad_for(season)
  end

  def ec_in_squad
    object.ec_in_squad_for(season)
  end

  def national_in_squad
    object.national_in_squad_for(season)
  end
end

class PlayerBaseSerializer < ActiveModel::Serializer
  attributes :id
  attributes :appearances
  attributes :appearances_max
  attributes :avatar_path
  attributes :average_base_score
  attributes :average_price
  attributes :average_total_score
  attributes :club
  attributes :first_name
  attributes :league_price
  attributes :league_team_logo
  attributes :leagues
  attributes :name
  attributes :position_classic_arr
  attributes :position_ital_arr
  attributes :stats_price
  attributes :teams_count
  attributes :teams_count_max

  attribute :newbie do
    object.newbie?
  end

  def appearances
    return season_stats_rows.sum(&:played_matches) if season_stats_rows.any?

    current_season? ? object.season_scores_count : 0
  end

  def appearances_max
    season_round_players.size
  end

  def average_base_score
    return weighted_stat(:score) if season_stats_rows.any?

    current_season? ? object.season_average_score : 0
  end

  def average_price
    current_season? ? object.current_average_price : nil
  end

  def average_total_score
    return weighted_stat(:final_score) if season_stats_rows.any?

    current_season? ? object.season_average_result_score : 0
  end

  def club
    ClubSerializer.new(object.club)
  end

  def league_price
    object.transfer_by(league_team)&.price if league_team
  end

  def league_team_logo
    league_team&.logo_path
  end

  def position_classic_arr
    player_positions.map { |pp| Slot::POS_MAPPING[pp.position.name] }
  end

  def position_ital_arr
    player_positions.map { |pp| pp.position.name }
  end

  def teams_count
    return nil unless current_season?

    teams&.count
  end

  def teams_count_max
    return nil unless current_season?

    active_leagues&.size || 0
  end

  def leagues
    teams.pluck(:league_id)
  end

  delegate :stats_price, to: :object

  private

  def active_leagues
    tournament = object.club&.tournament
    tournament&.leagues&.active
  end

  def league_team
    @league_team ||= object.team_by_league(instance_options[:league_id]) if instance_options[:league_id]
  end

  def season_stats_rows
    @season_stats_rows ||= object.player_season_stats.select { |s| s.season_id == current_season_id }
  end

  def weighted_stat(column)
    played = season_stats_rows.sum(&:played_matches)
    return 0 if played.zero?

    (season_stats_rows.sum { |s| s.public_send(column) * s.played_matches } / played).round(2)
  end

  def season_round_players
    @season_round_players ||= object.round_players.select { |rp| rp.tournament_round&.season_id == current_season_id }
  end

  def current_season?
    current_season_id == Season.last&.id
  end

  def current_season_id
    @current_season_id ||= instance_options[:season_id] || Season.last&.id
  end

  def player_positions
    @player_positions ||= object.player_positions
  end

  def teams
    @teams ||= object.teams
  end
end

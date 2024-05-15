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
  attributes :name
  attributes :position_classic_arr
  attributes :position_ital_arr
  attributes :teams_count
  attributes :teams_count_max

  def appearances
    object.season_scores_count
  end

  def appearances_max
    object.season_matches.size
  end

  def average_base_score
    object.season_average_score
  end

  def average_price
    object.current_average_price
  end

  def average_total_score
    object.season_average_result_score
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
    teams&.count
  end

  def teams_count_max
    object.club&.tournament&.leagues&.active&.size || 0
  end

  private

  def league_team
    @league_team ||= object.team_by_league(instance_options[:league_id]) if instance_options[:league_id]
  end

  def player_positions
    @player_positions ||= object.player_positions
  end

  def teams
    @teams ||= object.teams
  end
end

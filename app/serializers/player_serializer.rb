class PlayerSerializer < ActiveModel::Serializer
  attributes :avatar_path, :club_code, :club_name, :first_name, :id, :kit_path, :leagues,
             :name, :national_kit_path, :national_team_name, :position_arr, :position_names

  def club_code
    object.club&.code
  end

  def club_name
    object.club&.name
  end

  def leagues
    object.teams.map(&:league_id)
  end

  def national_team_name
    object.national_team&.name
  end

  def position_arr
    object.player_positions.map { |pp| pp.position.name }
  end
end

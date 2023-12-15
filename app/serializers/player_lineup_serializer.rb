class PlayerLineupSerializer < ActiveModel::Serializer
  attributes :id
  attributes :avatar_path
  attributes :club_code
  attributes :club_color
  attributes :club_logo
  attributes :club_name
  attributes :first_name
  attributes :kit_path
  attributes :leagues
  attributes :name
  attributes :national_kit_path
  attributes :national_team_name
  attributes :position_arr
  attributes :position_classic_arr
  attributes :stats_price

  def club_code
    club&.code
  end

  def club_color
    club&.color
  end

  def club_logo
    club&.logo_path
  end

  def club_name
    club&.name
  end

  def leagues
    object.teams.pluck(:league_id)
  end

  def national_team_name
    object.national_team&.name
  end

  def position_arr
    player_positions.map { |pp| pp.position.name }
  end

  def position_classic_arr
    player_positions.map { |pp| Slot::POS_MAPPING[pp.position.name] }
  end

  private

  def club
    @club ||= object.club
  end

  def player_positions
    @player_positions ||= object.player_positions
  end
end

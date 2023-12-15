class PlayerSerializer < PlayerBaseSerializer
  # attributes from PlayerBaseSerializer
  # :id, :appearances, :avatar_path, :average_base_score, :average_price, :average_total_score, :club, :first_name,
  # :league_price, :league_team_logo, :name, :position_classic_arr, :position_ital_arr, :teams_count
  attributes :age
  attributes :birth_date
  attributes :country
  attributes :height
  attributes :leagues
  attributes :national_team
  attributes :number
  attributes :profile_avatar_path
  attributes :stats_price
  attributes :team_ids
  attributes :tm_price
  attributes :tm_url

  def leagues
    teams.pluck(:league_id)
  end

  def national_team
    NationalTeamSerializer.new(object.national_team) if object.national_team
  end

  def team_ids
    teams.pluck(:id)
  end
end

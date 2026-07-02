class PlayerSerializer < PlayerBaseSerializer
  # attributes from PlayerBaseSerializer
  # :id, :appearances, :avatar_path, :average_base_score, :average_price, :average_total_score, :club, :first_name,
  # :league_price, :league_team_logo, :leagues, :name, :position_classic_arr, :position_ital_arr, :stats_price, :teams_count
  attributes :age
  attributes :birth_date
  attributes :club_transfers
  attributes :country
  attributes :height
  attributes :national_team
  attributes :nationality
  attributes :number
  attributes :profile_avatar_path
  attributes :profile_kit_path
  attributes :season_score
  attributes :team_ids
  attributes :tm_price
  attributes :tm_url

  attribute :teams do
    object.teams.map { |team| serialize_team(team) }
  end

  def national_team
    NationalTeamSerializer.new(object.national_team) if object.national_team
  end

  def team_ids
    teams.pluck(:id)
  end

  def club_transfers
    object.club_transfers.sort_by(&:start_date).reverse.map { |ct| ClubTransferSerializer.new(ct) }
  end

  def season_score
    object.season_average_result_score(object.season_club_matches_w_scores)
  end

  private

  def serialize_team(team)
    transfer = object.transfer_by(team)
    auction = transfer&.auction

    {
      id: team.id,
      human_name: team.human_name,
      logo_path: team.logo_path,
      league_id: team.league_id,
      league_name: team.league.name,
      division_name: team.league.division&.name,
      auction_id: auction&.id,
      auction_number: auction&.number,
      auction_date: auction&.updated_at,
      price: transfer&.price
    }
  end
end

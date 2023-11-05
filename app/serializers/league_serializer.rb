class LeagueSerializer < ActiveModel::Serializer
  attributes :id, :division, :leader, :name, :round, :season_end_year, :season_start_year, :status,
             :teams_count, :tournament_logo, :tournament_name

  def division
    object.division&.name
  end

  def leader
    # object.leader
  end

  def round
    # object.active_tour&.number || object.tours.count
  end

  def season_end_year
    object.season.end_year
  end

  def season_start_year
    object.season.start_year
  end

  def teams_count
    object.results.count
  end

  def tournament_logo
    object.tournament.logo_path
  end

  def tournament_name
    object.tournament.name
  end
end

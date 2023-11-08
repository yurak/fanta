class LeagueSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include LeaguesHelper

  attributes :id
  attributes :division
  attributes :leader
  attributes :link
  attributes :name
  attributes :round
  attributes :season_end_year
  attributes :season_start_year
  attributes :status
  attributes :teams_count
  attributes :tournament_id

  def division
    object.division&.name
  end

  def leader
    # object.leader
  end

  def link
    league_link(object)
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
end

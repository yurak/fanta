class LeagueSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include LeaguesHelper

  attributes :id
  attributes :auction_type
  attributes :cloning_status
  attributes :division
  attributes :division_id
  attributes :leader
  attributes :leader_logo
  attributes :link
  attributes :mantra_format
  attributes :max_avg_def_score
  attributes :min_avg_def_score
  attributes :name
  attributes :promotion
  attributes :relegation
  attributes :round
  attributes :season_id
  attributes :season_end_year
  attributes :season_start_year
  attributes :status
  attributes :teams_count
  attributes :tournament_id
  attributes :transfer_status

  def division
    object.division&.name
  end

  def leader
    leader_team&.human_name
  end

  def leader_logo
    ActionController::Base.helpers.asset_path(leader_team.logo_path) if leader_team
  end

  def link
    league_link(object)
  end

  def mantra_format
    !object.tournament.fanta?
  end

  def round
    object.active_tour&.number || object.tours.count
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

  private

  def leader_team
    @leader_team ||= object.leader
  end
end

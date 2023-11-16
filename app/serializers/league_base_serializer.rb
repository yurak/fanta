class LeagueBaseSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include LeaguesHelper

  attributes :id
  attributes :division
  attributes :division_id
  attributes :link
  attributes :name
  attributes :season_id
  attributes :status
  attributes :tournament_id

  def division
    object.division&.name
  end

  def link
    league_link(object)
  end
end

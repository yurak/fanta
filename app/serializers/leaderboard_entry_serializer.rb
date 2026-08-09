class LeaderboardEntrySerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  COLLAPSE_THRESHOLD = 5
  COLLAPSED_LOGOS = 3

  attributes :id, :rank, :value, :matches, :champion_number,
             :name, :avatar_path, :team_logos, :extra_teams, :profile_path

  def rank
    instance_options[:rank]
  end

  def value
    instance_options[:value]
  end

  def matches
    instance_options[:matches]
  end

  def avatar_path
    ActionController::Base.helpers.asset_path(object.avatar_path)
  end

  def team_logos
    shown = collapsed? ? mantra_teams.last(COLLAPSED_LOGOS) : mantra_teams
    shown.map(&:logo_path)
  end

  def extra_teams
    collapsed? ? mantra_teams.size - COLLAPSED_LOGOS : 0
  end

  def profile_path
    manager_path(object)
  end

  private

  def collapsed?
    mantra_teams.size >= COLLAPSE_THRESHOLD
  end

  def mantra_teams
    @mantra_teams ||= object.teams.select do |team|
      team.league&.tournament&.mantra? && team.results.any? { |result| result.matches_played.positive? }
    end
  end
end

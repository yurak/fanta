class Standing < ApplicationRecord
  belongs_to :tournament
  belongs_to :season
  belongs_to :club, optional: true

  validates :position, presence: true

  scope :ordered, -> { order(:position) }
  scope :by_season, ->(season_id) { where(season_id: season_id) }

  def goal_diff
    goals_for - goals_against
  end

  def scores_str
    "#{goals_for}-#{goals_against}"
  end

  def display_name
    club&.name.presence || team_name
  end
end

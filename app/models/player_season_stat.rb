class PlayerSeasonStat < ApplicationRecord
  belongs_to :club
  belongs_to :player
  belongs_to :season
  belongs_to :tournament

  default_scope { includes(%i[club season]) }

  scope :by_position, ->(position) { where('position1 LIKE :pos OR position2 LIKE :pos OR position3 LIKE :pos', pos: position) }
  scope :played_minimum, -> { where('played_matches > ?', 13) }
  scope :by_season, ->(season) { where(season: season) }

  def position_ital_arr
    [position1, position2, position3].compact
  end
end

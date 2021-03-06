class TournamentRound < ApplicationRecord
  belongs_to :tournament
  belongs_to :season

  has_many :national_matches, dependent: :destroy
  has_many :round_players, dependent: :destroy
  has_many :tournament_matches, dependent: :destroy
  has_many :tours, dependent: :destroy

  scope :by_tournament, ->(tournament_id) { where(tournament: tournament_id) }
  scope :by_season, ->(season_id) { where(season: season_id) }
end

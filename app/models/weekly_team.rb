class WeeklyTeam < ApplicationRecord
  belongs_to :team_module
  belongs_to :season
  belongs_to :tournament, optional: true

  has_many :weekly_team_players, dependent: :destroy
  has_many :round_players, through: :weekly_team_players

  serialize :round_ids, Array

  enum mode: { top: 'top', flop: 'flop' }
  enum source: { round: 'round', season: 'season', avg: 'avg' }, _prefix: :source

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :mode, presence: true
  validates :mode, inclusion: { in: %w[top] }, if: :source_avg?
  validates :tournament, presence: true, if: -> { source_season? || source_avg? }
end

class WeeklyTeam < ApplicationRecord
  belongs_to :team_module
  belongs_to :season

  has_many :weekly_team_players, dependent: :destroy
  has_many :round_players, through: :weekly_team_players

  serialize :round_ids, Array

  enum mode: { top: 'top', flop: 'flop' }

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :mode, presence: true
end

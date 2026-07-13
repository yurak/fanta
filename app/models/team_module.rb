class TeamModule < ApplicationRecord
  has_many :slots, -> { order(:number) }, dependent: :destroy, inverse_of: :team_module
  has_many :lineups, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end

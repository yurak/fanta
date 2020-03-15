class TeamModule < ApplicationRecord
  has_many :slots, dependent: :destroy
  has_many :lineups, dependent: :destroy

  validates :name, uniqueness: true
end

class TeamModule < ApplicationRecord
  validates :name, uniqueness: true

  has_many :slots, dependent: :destroy
  has_many :lineups, dependent: :destroy
end

class TeamModule < ApplicationRecord
  validates :name, uniqueness: true

  # TODO: change to has_many :slots, through:
  has_many :slots, dependent: :destroy
  has_many :lineups, dependent: :destroy
end

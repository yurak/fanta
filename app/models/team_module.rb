class TeamModule < ApplicationRecord
  validates :name, uniqueness: true

  # TODO: change to has_and_belongs_to_many :slots
  has_many :slots, dependent: :destroy
  has_many :lineups, dependent: :destroy
end

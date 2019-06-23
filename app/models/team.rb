class Team < ApplicationRecord
  has_many :players, dependent: :destroy

  validates :name, uniqueness: true

  has_many :lineups, dependent: :destroy
end

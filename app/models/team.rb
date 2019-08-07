class Team < ApplicationRecord
  belongs_to :user, optional: true
  has_many :players, dependent: :destroy
  has_many :lineups, dependent: :destroy

  validates :name, uniqueness: true
end

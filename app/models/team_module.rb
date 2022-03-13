class TeamModule < ApplicationRecord
  has_many :slots, dependent: :destroy
  has_many :lineups, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end

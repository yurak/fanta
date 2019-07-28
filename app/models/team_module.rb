class TeamModule < ApplicationRecord
  has_many :slots, dependent: :destroy

  validates :name, uniqueness: true
end

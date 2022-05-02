class PlayerRequest < ApplicationRecord
  belongs_to :player
  belongs_to :user

  validates :positions, presence: true
end

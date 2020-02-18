class Tournament < ApplicationRecord
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  has_many :leagues
  has_many :clubs
end

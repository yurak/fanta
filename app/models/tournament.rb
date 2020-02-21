class Tournament < ApplicationRecord
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true

  has_many :leagues, dependent: :destroy
  has_many :clubs, dependent: :destroy
end

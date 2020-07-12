class Season < ApplicationRecord
  has_many :leagues, dependent: :destroy

  MIN_START_YEAR = 2019
  MIN_END_YEAR = 2020

  validates :start_year, presence: true, uniqueness: true, numericality: { greater_than_or_equal_to: MIN_START_YEAR }
  validates :end_year, presence: true, uniqueness: true, numericality: { greater_than_or_equal_to: MIN_END_YEAR }
end

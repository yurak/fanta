class League < ApplicationRecord
  belongs_to :tournament
  belongs_to :season

  has_many :teams, dependent: :destroy
  has_many :tours, dependent: :destroy
  has_many :links, dependent: :destroy
  has_many :results, dependent: :destroy

  enum status: %i[initial active archived]

  validates :name, presence: true, uniqueness: true

  def active_tour
    tours&.active&.first || tours.inactive&.first
  end
end

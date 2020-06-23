class League < ApplicationRecord
  belongs_to :tournament

  has_many :teams, dependent: :destroy
  has_many :tours, dependent: :destroy
  has_many :links, dependent: :destroy

  enum status: %i[initial active archived]

  validates :name, presence: true, uniqueness: true

  def active_tour
    tours&.active&.first || tours.inactive&.first
  end
end

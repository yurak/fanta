class League < ApplicationRecord
  has_many :teams, dependent: :destroy
  has_many :tours, dependent: :destroy
  has_many :links, dependent: :destroy
  belongs_to :tournament

  enum status: %i[initial active archived]

  def active_tour
    tours&.active
  end
end

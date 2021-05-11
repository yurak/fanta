class NationalTeam < ApplicationRecord
  belongs_to :tournament

  has_many :players, dependent: :destroy

  validates :code, presence: true, uniqueness: true
end

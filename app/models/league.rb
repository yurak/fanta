class League < ApplicationRecord
  has_many :teams
  has_many :tours
  has_many :links
  belongs_to :tournament

  enum status: %i[initial active archived]
end

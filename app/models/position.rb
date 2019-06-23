class Position < ApplicationRecord
  validates :name, uniqueness: true

  has_and_belongs_to_many :players

  DEFENSIVE = ['Por', 'Dc', 'Ds', 'Dd'].freeze
end

class Club < ApplicationRecord
  validates :name, uniqueness: true

  has_many :players

  def code
    name[0..2].upcase
  end
end

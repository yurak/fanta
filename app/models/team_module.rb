class TeamModule < ApplicationRecord
  has_many :slots, dependent: :destroy

  validates :name, uniqueness: true

  def lines
    [1].concat(name.split('-').map(&:to_i))
  end
end

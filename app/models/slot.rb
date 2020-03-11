class Slot < ApplicationRecord
  # TODO: change to has_many :team_modules, through:
  belongs_to :team_module

  def positions
    position.split('/')
  end

  def positions_with_malus
    positions.map { |p| Position::DEPENDENCY[p] }.flatten.uniq
  end
end

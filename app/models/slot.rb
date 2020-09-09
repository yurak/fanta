class Slot < ApplicationRecord
  belongs_to :team_module

  def positions
    position ? position.split('/') : []
  end

  def positions_with_malus
    positions.map { |p| Position::DEPENDENCY[p] }.flatten.uniq
  end
end

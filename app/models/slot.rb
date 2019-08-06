class Slot < ApplicationRecord
  def positions
    position.split('/')
  end

  def positions_with_malus
    positions.map{|p|  Position::DEPENDENCY[p]}.flatten.uniq
  end
end

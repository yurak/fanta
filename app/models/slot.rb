class Slot < ApplicationRecord
  # TODO: change to has_and_belongs_to_many :team_modules
  belongs_to :team_module

  def positions
    position.split('/')
  end

  def positions_with_malus
    positions.map{|p|  Position::DEPENDENCY[p]}.flatten.uniq
  end
end

class Slot < ApplicationRecord
  belongs_to :team_module

  POS_MAPPING = {
    Position::GOALKEEPER => 'GK',
    Position::LEFT_BACK => 'LB',
    Position::RIGHT_BACK => 'RB',
    Position::CENTER_BACK => 'CB',
    Position::WING_BACK => 'WB',
    Position::DEFENCE_MF => 'DM',
    Position::CENTER_MF => 'CM',
    Position::WINGER => 'W',
    Position::ATTACKING_MF => 'AM',
    Position::FORWARD => 'FW',
    Position::STRIKER => 'ST',
    'M/C' => 'DM/CM',
    'W/A' => 'W/FW',
    'A/Pc' => 'FW/ST',
    'E/W' => 'WB/W',
    'T/A' => 'AM/FW',
    'C/T' => 'CM/AM',
    'W/T' => 'W/AM'
  }.freeze

  def positions
    position ? position.split('/') : []
  end

  def positions_with_malus
    positions.map { |p| Position::DEPENDENCY[p] }.flatten.uniq
  end
end

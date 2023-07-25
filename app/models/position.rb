# frozen_string_literal: true

class Position < ApplicationRecord
  has_many :player_positions, dependent: :destroy
  has_many :players, through: :player_positions

  validates :name, presence: true
  validates :name, uniqueness: true

  GOALKEEPER = 'Por'
  LEFT_BACK = 'Ds'
  RIGHT_BACK = 'Dd'
  CENTER_BACK = 'Dc'
  WING_BACK = 'E'
  DEFENCE_MF = 'M'
  CENTER_MF = 'C'
  WINGER = 'W'
  ATTACKING_MF = 'T'
  FORWARD = 'A'
  STRIKER = 'Pc'

  S_MALUS = 1.5
  M_MALUS = 3.0
  L_MALUS = 4.5

  LIST = [GOALKEEPER, CENTER_BACK, LEFT_BACK, RIGHT_BACK, WING_BACK, DEFENCE_MF, CENTER_MF, WINGER, ATTACKING_MF, FORWARD, STRIKER].freeze
  CLEANSHEET_ZONE = [GOALKEEPER, CENTER_BACK, LEFT_BACK, RIGHT_BACK, DEFENCE_MF, WING_BACK].freeze
  D_CLEANSHEET_ZONE = [CENTER_BACK, LEFT_BACK, RIGHT_BACK].freeze
  E_CLEANSHEET_ZONE = [LEFT_BACK, RIGHT_BACK, WING_BACK].freeze
  E_M_CLEANSHEET_ZONE = [DEFENCE_MF, WING_BACK].freeze

  DEFENCE = [CENTER_BACK, LEFT_BACK, RIGHT_BACK].freeze

  # Position in lineup => Native Positions
  DEPENDENCY = {
    GOALKEEPER => [GOALKEEPER],
    LEFT_BACK => [LEFT_BACK, RIGHT_BACK, CENTER_BACK, WING_BACK],
    RIGHT_BACK => [RIGHT_BACK, LEFT_BACK, CENTER_BACK, WING_BACK],
    CENTER_BACK => [CENTER_BACK, RIGHT_BACK, LEFT_BACK, DEFENCE_MF],
    WING_BACK => [WING_BACK, DEFENCE_MF, CENTER_MF, RIGHT_BACK, LEFT_BACK, WINGER],
    DEFENCE_MF => [DEFENCE_MF, CENTER_MF, WING_BACK, CENTER_BACK],
    CENTER_MF => [CENTER_MF, DEFENCE_MF, WING_BACK, ATTACKING_MF],
    WINGER => [WINGER, WING_BACK, ATTACKING_MF, FORWARD],
    ATTACKING_MF => [ATTACKING_MF, CENTER_MF, WINGER, FORWARD],
    FORWARD => [FORWARD, STRIKER, ATTACKING_MF, WINGER],
    STRIKER => [STRIKER, FORWARD]
  }.freeze

  # Position in lineup => Native Position => Malus size
  MALUS = {
    LEFT_BACK => { RIGHT_BACK => S_MALUS,
                   CENTER_BACK => S_MALUS,
                   WING_BACK => M_MALUS },
    RIGHT_BACK => { LEFT_BACK => S_MALUS,
                    CENTER_BACK => S_MALUS,
                    WING_BACK => M_MALUS },
    CENTER_BACK => { RIGHT_BACK => S_MALUS,
                     LEFT_BACK => S_MALUS,
                     DEFENCE_MF => M_MALUS },
    WING_BACK => { DEFENCE_MF => S_MALUS,
                   CENTER_MF => S_MALUS,
                   RIGHT_BACK => M_MALUS,
                   LEFT_BACK => M_MALUS,
                   WINGER => M_MALUS },
    DEFENCE_MF => { CENTER_MF => S_MALUS,
                    WING_BACK => S_MALUS,
                    CENTER_BACK => M_MALUS },
    CENTER_MF => { DEFENCE_MF => S_MALUS,
                   WING_BACK => S_MALUS,
                   ATTACKING_MF => M_MALUS },
    WINGER => { ATTACKING_MF => S_MALUS,
                WING_BACK => M_MALUS,
                FORWARD => M_MALUS },
    ATTACKING_MF => { WINGER => S_MALUS,
                      CENTER_MF => M_MALUS,
                      FORWARD => M_MALUS },
    FORWARD => { STRIKER => S_MALUS,
                 WINGER => M_MALUS,
                 ATTACKING_MF => M_MALUS },
    STRIKER => { FORWARD => S_MALUS }
  }.freeze

  # Position in Transfermarkt
  TM_POS = {
    'Goalkeeper' => 'GK',
    'Centre-Back' => 'CB',
    'Left-Back' => 'LB',
    'Right-Back' => 'RB',
    'Defensive Midfield' => 'DM',
    'Central Midfield' => 'CM',
    'Left Midfield' => 'LM',
    'Right Midfield' => 'RM',
    'Attacking Midfield' => 'AM',
    'Left Winger' => 'LW',
    'Right Winger' => 'RW',
    'Second Striker' => 'SS',
    'Centre-Forward' => 'CF'
  }.freeze
end

# frozen_string_literal: true

class Position < ApplicationRecord
  has_many :player_positions, dependent: :destroy
  has_many :players, through: :player_positions

  validates :name, uniqueness: true

  PORTIERE = 'Por'
  ESTERNO  = 'E'
  DIFENSORE_SINISTRO = 'Ds'
  DIFENSORE_DESTRO   = 'Dd'
  DIFENSORE_CENTRALE = 'Dc'
  MEDIANO = 'M'
  CENTROCAMPISTA = 'C'
  ALA = 'W'
  TREQUARTSITA = 'T'
  ATTACCANTE = 'A'
  PUNTA = 'Pc'

  S_MALUS = 1.5
  M_MALUS = 3.0
  L_MALUS = 4.5

  DEFENSIVE = [PORTIERE, DIFENSORE_CENTRALE, DIFENSORE_SINISTRO, DIFENSORE_DESTRO].freeze

  DEFENCE = [DIFENSORE_CENTRALE, DIFENSORE_SINISTRO, DIFENSORE_DESTRO].freeze

  MANTRA = [
             PORTIERE,
             ESTERNO,
             DIFENSORE_SINISTRO,
             DIFENSORE_DESTRO,
             DIFENSORE_CENTRALE,
             MEDIANO,
             CENTROCAMPISTA,
             TREQUARTSITA,
             ATTACCANTE,
             PUNTA
           ].freeze

  DEPENDENCY = {
    PORTIERE => [PORTIERE],
    DIFENSORE_SINISTRO => [DIFENSORE_SINISTRO, DIFENSORE_DESTRO, DIFENSORE_CENTRALE, ESTERNO, ALA],
    DIFENSORE_DESTRO => [DIFENSORE_DESTRO, DIFENSORE_SINISTRO, DIFENSORE_CENTRALE, ESTERNO, ALA],
    DIFENSORE_CENTRALE => [DIFENSORE_CENTRALE, DIFENSORE_DESTRO, DIFENSORE_SINISTRO],
    ESTERNO => [ESTERNO, DIFENSORE_DESTRO, DIFENSORE_SINISTRO, ALA],
    MEDIANO => [MEDIANO, CENTROCAMPISTA, TREQUARTSITA],
    CENTROCAMPISTA => [CENTROCAMPISTA, MEDIANO, TREQUARTSITA],
    ALA => [ALA, DIFENSORE_DESTRO, DIFENSORE_SINISTRO, ESTERNO, TREQUARTSITA],
    TREQUARTSITA => [TREQUARTSITA, MEDIANO, CENTROCAMPISTA, ALA, ATTACCANTE],
    ATTACCANTE => [ATTACCANTE, PUNTA, TREQUARTSITA],
    PUNTA => [PUNTA, ATTACCANTE, TREQUARTSITA]
  }.freeze

  # Position in lineup => Native Position => Malus size
  MALUS = {
    DIFENSORE_SINISTRO => { DIFENSORE_DESTRO => S_MALUS,
                            DIFENSORE_CENTRALE => M_MALUS,
                            ESTERNO => M_MALUS,
                            ALA => L_MALUS },
    DIFENSORE_DESTRO => { DIFENSORE_SINISTRO => S_MALUS,
                          DIFENSORE_CENTRALE => M_MALUS,
                          ESTERNO => M_MALUS,
                          ALA => L_MALUS },
    DIFENSORE_CENTRALE => { DIFENSORE_DESTRO => S_MALUS,
                            DIFENSORE_SINISTRO => S_MALUS },
    ESTERNO => { DIFENSORE_DESTRO => M_MALUS,
                 DIFENSORE_SINISTRO => M_MALUS,
                 ALA => M_MALUS },
    MEDIANO => { CENTROCAMPISTA => S_MALUS,
                 TREQUARTSITA => M_MALUS },
    CENTROCAMPISTA => { MEDIANO => S_MALUS,
                        TREQUARTSITA => M_MALUS },
    ALA => { TREQUARTSITA => S_MALUS,
             ESTERNO => M_MALUS,
             DIFENSORE_SINISTRO => L_MALUS,
             DIFENSORE_DESTRO => L_MALUS },
    TREQUARTSITA => { ALA => S_MALUS,
                      MEDIANO => M_MALUS,
                      CENTROCAMPISTA => M_MALUS,
                      ATTACCANTE => M_MALUS },
    ATTACCANTE => { PUNTA => S_MALUS,
                    TREQUARTSITA => M_MALUS },
    PUNTA => { ATTACCANTE => S_MALUS,
               TREQUARTSITA => M_MALUS }
  }.freeze
end

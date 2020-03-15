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
end

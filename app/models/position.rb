# frozen_string_literal: true

class Position < ApplicationRecord
  validates :name, uniqueness: true

  has_and_belongs_to_many :players

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
    DIFENSORE_SINISTRO => [DIFENSORE_DESTRO, DIFENSORE_SINISTRO, DIFENSORE_CENTRALE, ESTERNO],
    DIFENSORE_DESTRO => [DIFENSORE_DESTRO, DIFENSORE_SINISTRO, DIFENSORE_CENTRALE, ESTERNO],
    DIFENSORE_CENTRALE => [DIFENSORE_DESTRO, DIFENSORE_SINISTRO, DIFENSORE_CENTRALE],
    ESTERNO => [DIFENSORE_DESTRO, DIFENSORE_SINISTRO, ESTERNO, ALA],
    MEDIANO => [MEDIANO, CENTROCAMPISTA, TREQUARTSITA],
    CENTROCAMPISTA => [MEDIANO, CENTROCAMPISTA, TREQUARTSITA],
    ALA => [DIFENSORE_DESTRO, DIFENSORE_SINISTRO, ALA, ESTERNO, TREQUARTSITA],
    TREQUARTSITA => [TREQUARTSITA, MEDIANO, CENTROCAMPISTA, ALA, ATTACCANTE, PUNTA],
    ATTACCANTE => [ATTACCANTE, PUNTA, TREQUARTSITA],
    PUNTA => [ATTACCANTE, PUNTA, TREQUARTSITA]
  }.freeze
end

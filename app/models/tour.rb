class Tour < ApplicationRecord
  belongs_to :league
  belongs_to :tournament_round

  has_many :matches, dependent: :destroy
  has_many :lineups, dependent: :destroy

  delegate :teams, to: :league

  enum status: { inactive: 0, set_lineup: 1, locked: 2, closed: 3, postponed: 4 }

  scope :closed_postponed, -> { closed.or(postponed) }
  scope :active, -> { set_lineup.or(locked) }

  PLAYERS_BY_NATIONAL_MATCHES = [0, 7, 4, 3, 2].freeze

  def locked_or_postponed?
    locked? || postponed?
  end

  def deadlined?
    locked_or_postponed? || closed?
  end

  def unlocked?
    inactive? || set_lineup?
  end

  def mantra?
    tournament_round.tournament_matches.any?
  end

  def national?
    tournament_round.national_matches.any?
  end

  def national_teams_count
    return 0 unless tournament_round.national_matches

    tournament_round.national_matches.count * 2
  end

  def max_country_players
    PLAYERS_BY_NATIONAL_MATCHES[tournament_round.national_matches&.count] || 0
  end

  def lineup_exist?(team)
    lineups.find_by(team_id: team.id).present?
  end

  def match_players
    MatchPlayer.by_tour(id)
  end

  def next_round
    return if number >= league.tours.size

    league.tours.find_by(number: number + 1)
  end

  def prev_round
    return if number <= 1

    league.tours.find_by(number: number - 1)
  end

  def ordered_lineups
    lineups.sort { |a, b| b.total_score <=> a.total_score }
  end
end

class TournamentRound < ApplicationRecord
  belongs_to :tournament
  belongs_to :season

  has_many :national_matches, dependent: :destroy
  has_many :round_players, dependent: :destroy
  has_many :tournament_matches, dependent: :destroy
  has_many :tours, dependent: :destroy
  has_many :lineups, through: :tours

  delegate :fanta?, :mantra?, to: :tournament

  scope :by_tournament, ->(tournament_id) { where(tournament: tournament_id) }
  scope :by_season, ->(season_id) { where(season: season_id) }
  scope :moderated, -> { where.not(moderated_at: nil) }

  MODERATED_HOURS = 18

  def eurocup_players
    return [] unless tournament.eurocup?

    round_players.by_club(clubs_ids)
  end

  def clubs_ids
    tournament_matches.pluck(:host_club_id, :guest_club_id).flatten
  end

  def finished?
    return @finished unless @finished.nil?

    @finished = [tournament_matches, national_matches].any? { |matches| matches_finished?(matches) }
  end

  def time_to_deadline
    return '' unless deadline

    TimeDifference.between(deadline, Time.zone.now).in_general
  end

  def closing_time
    return unless moderated_at

    moderated_at + MODERATED_HOURS.hours
  end

  def best_lineups
    return @best_lineups if defined?(@best_lineups)

    max_score = lineups.maximum(:final_score)
    return @best_lineups = [] if max_score.to_f <= 0

    @best_lineups = lineups.where(final_score: max_score).to_a
  end

  def worst_lineups
    return @worst_lineups if defined?(@worst_lineups)

    min_score = lineups.where('final_score > 0').minimum(:final_score)
    return @worst_lineups = [] unless min_score

    @worst_lineups = lineups.where(final_score: min_score).to_a
  end

  def best_bench
    @best_bench ||= lineups.includes(match_players: :round_player).max_by(&:average_bench)
  end

  private

  def worst_lineup
    lineups.min_by(&:total_score)
  end

  def matches_finished?(matches)
    matches.exists? && !matches.exists?(host_score: nil)
  end
end

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

    TimeDifference.between(deadline.asctime.in_time_zone('EET'), Time.zone.now).in_general
  end

  def best_lineups
    return @best_lineup if defined?(@best_lineup)

    max_score = lineups.maximum(:final_score)
    return @best_lineup = [] if max_score.to_f <= 0

    @best_lineup = lineups.where(final_score: max_score).to_a
  end

  def worst_lineups
    return @worst_lineup if defined?(@worst_lineup)

    min_score = lineups.where("final_score > 0").minimum(:final_score)
    return @worst_lineup = [] unless min_score

    @worst_lineup = lineups.where(final_score: min_score).to_a
  end

  def best_bench
    lineups.max_by(&:average_bench)
  end

  private

  def matches_finished?(matches)
    matches.exists? && !matches.exists?(host_score: nil)
  end
end

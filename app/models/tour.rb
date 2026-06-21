class Tour < ApplicationRecord
  belongs_to :league
  belongs_to :tournament_round

  has_many :matches, dependent: :destroy
  has_many :lineups, dependent: :destroy
  has_many :round_players, through: :tournament_round

  delegate :teams, to: :league
  delegate :fanta?, :mantra?, to: :tournament_round

  enum :status, { inactive: 0, set_lineup: 1, locked: 2, closed: 3, postponed: 4 }
  enum :bench_status, { default_bench: 0, expanded: 1 }

  scope :closed_postponed, -> { closed.or(postponed) }
  scope :locked_postponed, -> { locked.or(postponed) }
  scope :active, -> { set_lineup.or(locked) }

  MIN_PLAYERS_BY_FANTA_MATCHES = [0, 8, 4, 2, 2, 1, 1, 1, 1, 0].freeze
  MAX_PLAYERS_BY_FANTA_MATCHES = [0, 8, 4, 3, 2, 2, 2, 2, 1, 1].freeze

  def locked_or_postponed?
    locked? || postponed?
  end

  def deadlined?
    locked_or_postponed? || closed?
  end

  def unlocked?
    inactive? || set_lineup?
  end

  def national?
    @national ||= tournament_round.national_matches.exists?
  end

  def eurocup?
    @eurocup ||= tournament_round.tournament.eurocup?
  end

  def national_teams_count
    return 0 unless national?

    tournament_round.national_matches.count * 2
  end

  def max_country_players
    if national?
      MAX_PLAYERS_BY_FANTA_MATCHES[tournament_round.national_matches&.count] || 0
    elsif eurocup?
      MAX_PLAYERS_BY_FANTA_MATCHES[tournament_round.tournament_matches&.count] || 0
    else
      0
    end
  end

  def min_country_players
    if national?
      MIN_PLAYERS_BY_FANTA_MATCHES[tournament_round.national_matches&.count] || 0
    elsif eurocup?
      MIN_PLAYERS_BY_FANTA_MATCHES[tournament_round.tournament_matches&.count] || 0
    else
      0
    end
  end

  def lineup_exist?(team)
    lineups.find_by(team_id: team.id).present?
  end

  def match_players
    MatchPlayer.by_tour(id)
  end

  def next_round
    @next_round ||= league.tours.detect { |t| t.number == number + 1 }
  end

  def prev_round
    @prev_round ||= league.tours.detect { |t| t.number == number - 1 }
  end

  def ordered_lineups
    lineups.includes(:team, match_players: :round_player).sort do |a, b|
      [b.total_score, b.best_main_score, b.best_bench_score, b.bench_total_score, a.last_edited_at] <=>
        [a.total_score, a.best_main_score, a.best_bench_score, a.bench_total_score, b.last_edited_at]
    end
  end

  def autobot(preview: true)
    if fanta?
      lineups.each do |lineup|
        Substitutes::AutoBot.call(lineup, preview: preview) if lineup.subs_missed?
      end
    else
      matches.each do |m|
        m.autobot(preview: preview)
      end
    end
  end

  def subs_preview
    lineups.map(&:substitutes_preview)
  end

  def subs_missed?
    match_players_with_preloads.any?(&:subs_option_exist?)
  end

  private

  def match_players_with_preloads
    @match_players_with_preloads ||= match_players
                                     .main
                                     .without_score
                                     .includes(
                                       lineup: :tour,
                                       round_player: [
                                         { tournament_round: :tournament },
                                         { player: [:positions, { national_team: :tournament },
                                                    { club: %i[tournament ec_tournament] }] }
                                       ]
                                     )
  end
end

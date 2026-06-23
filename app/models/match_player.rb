class MatchPlayer < ApplicationRecord
  belongs_to :round_player
  belongs_to :lineup, inverse_of: :match_players

  has_many :main_subs, foreign_key: 'main_mp_id', class_name: 'Substitute', dependent: :destroy, inverse_of: :main_mp
  has_many :reserve_subs, foreign_key: 'reserve_mp_id', class_name: 'Substitute', dependent: :destroy, inverse_of: :reserve_mp

  delegate :league, :team, :tour, to: :lineup
  delegate :another_tournament?, :assists, :caught_penalty, :cleansheet, :club_played_match?, :conceded_penalty,
           :failed_penalty, :goals, :missed_goals, :missed_penalty, :own_goals, :penalties_won, :player, :red_card, :result_score,
           :saves, :score, :scored_penalty, :yellow_card, to: :round_player
  delegate :club, :first_name, :name, :teams, to: :player

  enum :subs_status, { initial: 0, get_out: 1, get_in: 2, not_in_squad: 3 }

  default_scope { includes(:lineup, round_player: { player: %i[club player_positions positions] }) }

  FOR_FORM_ORDER = Arel.sql('CASE WHEN real_position IS NULL THEN 1 ELSE 0 END, match_players.id ASC').freeze

  scope :main, -> { where.not(real_position: nil).order(:id) }
  scope :for_form, -> { order(FOR_FORM_ORDER) }
  scope :with_score, -> { includes(:round_player).joins(:round_player).where('round_players.score > ?', 0) }
  scope :main_with_score, -> { main.with_score }
  scope :subs, -> { where(real_position: nil) }
  scope :subs_bench, -> { subs.where.not(subs_status: :not_in_squad).order(:id) }
  scope :not_in_lineup, -> { subs.where(subs_status: :not_in_squad) }
  scope :without_score, -> { joins(:round_player).where('round_players.score': 0) }
  scope :by_tour, ->(tour_id) { joins(:lineup).where(lineups: { tour_id: tour_id }) }
  scope :by_league, ->(league_id) { joins(lineup: :tour).where(tours: { league_id: league_id }) }
  scope :reservists_by_tour, ->(tour_id) { subs.by_tour(tour_id) }
  scope :defenders, -> { where(real_position: Position::DEFENCE) }
  scope :by_real_position, ->(position) { where('real_position LIKE ?', "%#{position}%") }

  CLEANSHEET_BONUS_DIFF_FULL = 1
  CLEANSHEET_BONUS_DIFF = 0.5
  MIN_PLAYED_MINUTES_FOR_CS = 60

  def kit_path
    round_player.related_club&.kit_path || player.kit_path
  end

  def not_played?
    score.zero? && (club_played_match? || another_tournament?)
  end

  def position_malus?
    return false unless real_position

    (real_position_arr & position_names).empty?
  end

  def total_score
    return 0 unless score

    total = result_score

    total -= recount_cleansheet if cleansheet && real_position
    total -= position_malus if position_malus

    total
  end

  def position_names
    return player_positions.split('/') if player_positions.present?

    player.position_names
  end

  def available_positions
    real_position_arr.map { |p| Position::DEPENDENCY[p] }.flatten.uniq
  end

  def real_position_arr
    real_position ? real_position.split('/') : []
  end

  def hide_cleansheet?
    e_not_at_valid_pos? || m_not_at_valid_pos?
  end

  def subs_option_exist?
    subs_options.exists?
  end

  def subs_options
    return MatchPlayer.none unless eligible_for_subs?

    lineup.match_players
          .subs_bench
          .with_score
          .joins(round_player: { player: :positions })
          .where(positions: { name: available_positions })
          .distinct
  end

  private

  def eligible_for_subs?
    score.zero? &&
      (club_played_match? || another_tournament?) &&
      lineup.tour.locked_or_postponed? &&
      available_positions.present?
  end

  def recount_cleansheet
    if d_at_w? || d_at_c?
      CLEANSHEET_BONUS_DIFF_FULL
    elsif d_at_e_or_m? || m_not_at_valid_pos? || e_not_at_valid_pos?
      CLEANSHEET_BONUS_DIFF
    else
      0
    end
  end

  def d_at_w?
    d_player? && (real_position_arr & Position::E_CLEANSHEET_ZONE).empty? &&
      real_position_arr.include?(Position::WINGER)
  end

  def d_at_c?
    d_player? && out_of_cleansheet_zone? && real_position_arr.include?(Position::CENTER_MF)
  end

  def d_at_e_or_m?
    d_player? && (real_position_arr & [Position::WING_BACK, Position::DEFENCE_MF]).any?
  end

  def m_not_at_valid_pos?
    position_names.include?(Position::DEFENCE_MF) && out_of_cleansheet_zone?
  end

  def e_not_at_valid_pos?
    position_names.include?(Position::WING_BACK) && out_of_cleansheet_zone?
  end

  def d_player?
    (position_names & Position::D_CLEANSHEET_ZONE).any?
  end

  def out_of_cleansheet_zone?
    (real_position_arr & Position::CLEANSHEET_ZONE).empty?
  end
end

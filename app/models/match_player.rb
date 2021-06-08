class MatchPlayer < ApplicationRecord
  belongs_to :round_player
  belongs_to :lineup

  delegate :league, :team, :tour, to: :lineup
  delegate :assists, :caught_penalty, :cleansheet, :club_played_match?, :failed_penalty, :goals,
           :missed_goals, :missed_penalty, :own_goals, :player, :red_card, :result_score, :score, :scored_penalty,
           :yellow_card, to: :round_player
  delegate :club, :first_name, :name, :position_names, :teams, to: :player

  enum subs_status: { initial: 0, get_out: 1, get_in: 2, not_in_squad: 3 }

  scope :main, -> { where.not(real_position: nil) }
  scope :with_score, -> { includes(:round_player).joins(:round_player).where('round_players.score > ?', 0) }
  scope :subs, -> { where(real_position: nil) }
  scope :subs_bench, -> { where(real_position: nil).where.not(subs_status: :not_in_squad) }
  scope :without_score, -> { joins(:round_player).where('round_players.score': 0) }
  scope :by_tour, ->(tour_id) { joins(:lineup).where(lineups: { tour_id: tour_id }) }
  scope :reservists_by_tour, ->(tour_id) { subs.by_tour(tour_id) }
  scope :defenders, -> { where(real_position: Position::DEFENCE) }
  scope :by_real_position, ->(position) { where('real_position LIKE ?', "%#{position}%") }

  GOAL_PC_DIFF = -1
  GOAL_A_DIFF = -0.5
  CLEANSHEET_BONUS_DIFF = 0.5

  def not_played?
    score.zero? && club_played_match?
  end

  def position_malus?
    return false unless real_position

    (real_position_arr & position_names).empty?
  end

  def total_score
    return 0 unless score

    total = result_score
    total += custom_score if league.custom_bonuses

    total -= recount_cleansheet if cleansheet
    total -= position_malus if position_malus

    total
  end

  def available_positions
    real_position_arr.map { |p| Position::DEPENDENCY[p] }.flatten.uniq
  end

  def real_position_arr
    real_position ? real_position.split('/') : []
  end

  private

  def custom_score
    custom_diff = 0
    custom_diff += recount_goals if league.recount_goals && (real_position_arr & Position::FORWARDS).present? && goals.positive?
    custom_diff += recount_missed_goals if (main_squad_por? || reserve_por?) && missed_goals.positive?
    custom_diff += recount_failed_penalty if failed_penalty.positive?

    custom_diff
  end

  def recount_goals
    goal_diff = main_squad_pc? || reserve_pc? ? GOAL_PC_DIFF : GOAL_A_DIFF
    goal_diff * goals
  end

  def recount_missed_goals
    (RoundPlayer::MISSED_GOAL_MALUS - league.missed_goals) * missed_goals
  end

  def recount_failed_penalty
    (RoundPlayer::FAILED_PENALTY_MALUS - league.failed_penalty) * failed_penalty
  end

  def recount_cleansheet
    # TODO: recount cleansheet value for players with E/W positions at E module position;
    if d_at_e_or_m? || m_not_at_m?
      CLEANSHEET_BONUS_DIFF
    else
      0
    end
  end

  def d_at_e_or_m?
    (position_names & Position::D_CLEANSHEET_ZONE).any? &&
      (real_position_arr.include?(Position::ESTERNO) || real_position_arr.include?(Position::MEDIANO))
  end

  def m_not_at_m?
    position_names.include?(Position::MEDIANO) && real_position_arr.exclude?(Position::MEDIANO)
  end

  def main_squad_pc?
    real_position_arr.include?(Position::PUNTA)
  end

  def reserve_pc?
    real_position.blank? && position_names.include?(Position::PUNTA)
  end

  def main_squad_por?
    real_position_arr.include?(Position::PORTIERE)
  end

  def reserve_por?
    real_position.blank? && position_names.include?(Position::PORTIERE)
  end
end

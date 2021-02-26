class MatchPlayer < ApplicationRecord
  belongs_to :round_player
  belongs_to :lineup

  delegate :tour, :league, :team, to: :lineup
  delegate :player, :score, :result_score, :goals, :assists, :missed_goals,
           :caught_penalty, :missed_penalty, :scored_penalty, :failed_penalty,
           :own_goals, :yellow_card, :red_card, :club_played_match?, to: :round_player
  delegate :position_names, :name, :first_name, :club, :teams, to: :player

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
  BASE_CLEANSHEET_BONUS = 1
  CUSTOM_CLEANSHEET_BONUS = 0.5

  def team_by(league)
    player.teams.find_by(league: league)
  end

  def not_played?
    score.zero? && club_played_match?
  end

  def malus
    0 if own_position?
  end

  def own_position?
    position_names.include?(real_position)
  end

  def position_malus?
    return false unless real_position

    (real_position_arr & position_names).empty?
  end

  def total_score
    return 0 unless score

    total = result_score
    total += custom_score if league.custom_bonuses

    total += cleansheet_score if cleansheet
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

  def cleansheet_score
    # TODO: store cleansheet in RoundPlayer, in MatchPlayer only count it value
    return 0 if (real_position_arr & Position::CLEANSHEET_ZONE).blank?
    return 0 if (position_names & Position::CLEANSHEET_ZONE).blank?

    return 0 if !league.custom_bonuses && (real_position_arr & Position::CLASSIC_CLEANSHEET_ZONE).present?

    if league.cleansheet_m && real_position_arr.include?(Position::MEDIANO) && position_names.include?(Position::MEDIANO)
      CUSTOM_CLEANSHEET_BONUS
    else
      BASE_CLEANSHEET_BONUS
    end
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

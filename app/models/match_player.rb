class MatchPlayer < ApplicationRecord
  belongs_to :round_player
  belongs_to :lineup

  has_many :main_subs, foreign_key: 'main_mp_id', class_name: 'Substitute', dependent: :destroy, inverse_of: :main_mp
  has_many :reserve_subs, foreign_key: 'reserve_mp_id', class_name: 'Substitute', dependent: :destroy, inverse_of: :reserve_mp

  delegate :league, :team, :tour, to: :lineup
  delegate :assists, :caught_penalty, :cleansheet, :club_played_match?, :failed_penalty, :goals,
           :missed_goals, :missed_penalty, :own_goals, :player, :red_card, :result_score, :score, :scored_penalty,
           :yellow_card, to: :round_player
  delegate :club, :first_name, :name, :position_names, :teams, to: :player

  enum subs_status: { initial: 0, get_out: 1, get_in: 2, not_in_squad: 3 }

  default_scope { includes(round_player: { player: %i[club player_positions positions] }) }

  scope :main, -> { where.not(real_position: nil) }
  scope :with_score, -> { includes(:round_player).joins(:round_player).where('round_players.score > ?', 0) }
  scope :subs, -> { where(real_position: nil) }
  scope :subs_bench, -> { where(real_position: nil).where.not(subs_status: :not_in_squad) }
  scope :without_score, -> { joins(:round_player).where('round_players.score': 0) }
  scope :by_tour, ->(tour_id) { joins(:lineup).where(lineups: { tour_id: tour_id }) }
  scope :reservists_by_tour, ->(tour_id) { subs.by_tour(tour_id) }
  scope :defenders, -> { where(real_position: Position::DEFENCE) }
  scope :by_real_position, ->(position) { where('real_position LIKE ?', "%#{position}%") }

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

  def hide_cleansheet?
    e_not_at_e_or_d? || m_not_at_m_or_dc?
  end

  private

  def recount_cleansheet
    if d_at_e_or_m? || m_not_at_m_or_dc? || e_not_at_e_or_d?
      CLEANSHEET_BONUS_DIFF
    else
      0
    end
  end

  def d_at_e_or_m?
    (position_names & Position::D_CLEANSHEET_ZONE).any? &&
      (real_position_arr.include?(Position::ESTERNO) || real_position_arr.include?(Position::MEDIANO))
  end

  def m_not_at_m_or_dc?
    position_names.include?(Position::MEDIANO) && (real_position_arr & Position::CLEANSHEET_ZONE).empty?
  end

  def e_not_at_e_or_d?
    position_names.include?(Position::ESTERNO) && (position_names & Position::D_CLEANSHEET_ZONE).empty? &&
      (real_position_arr & Position::E_CLEANSHEET_ZONE).empty?
  end
end

class RoundPlayer < ApplicationRecord
  belongs_to :tournament_round
  belongs_to :player

  has_many :match_players, dependent: :destroy
  has_many :lineups, through: :match_players

  delegate :position_names, :positions, :name, :first_name, :full_name, :club, :teams, to: :player, allow_nil: true

  scope :by_tournament_round, ->(tournament_round_id) { where(tournament_round: tournament_round_id) }
  scope :by_club, ->(club_id) { joins(:player).where('players.club_id = ?', club_id) }
  scope :by_name_and_club, ->(name, club_id) { by_club(club_id).where('LOWER(players.name) = ?', name.downcase) }
  scope :with_score, -> { where('score > ?', 0) }
  scope :ordered_by_club, -> { joins(player: :club).order('clubs.name') }

  GOAL_BONUS = 3
  CAUGHT_PENALTY_BONUS = 3
  SCORED_PENALTY_BONUS = 2
  ASSIST_BONUS = 1

  MISSED_GOAL_MALUS = 1
  MISSED_PENALTY_MALUS = 1
  FAILED_PENALTY_MALUS = 3
  OWN_GOAL_MALUS = 2
  YELLOW_CARD_MALUS = 0.5
  RED_CARD_MALUS = 1

  def result_score
    return 0 unless score

    total = score

    # bonuses
    total += goals * GOAL_BONUS if goals
    total += caught_penalty * CAUGHT_PENALTY_BONUS if caught_penalty
    total += scored_penalty * SCORED_PENALTY_BONUS if scored_penalty
    total += assists * ASSIST_BONUS if assists

    # maluses
    total -= missed_goals * MISSED_GOAL_MALUS if missed_goals
    total -= missed_penalty * MISSED_PENALTY_MALUS if missed_penalty
    total -= failed_penalty * FAILED_PENALTY_MALUS if failed_penalty
    total -= own_goals * OWN_GOAL_MALUS if own_goals
    total -= YELLOW_CARD_MALUS if yellow_card
    total -= RED_CARD_MALUS if red_card

    total
  end
end

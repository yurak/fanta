class RoundPlayer < ApplicationRecord
  belongs_to :tournament_round
  belongs_to :player

  has_many :match_players, dependent: :destroy
  has_many :lineups, through: :match_players

  has_many :in_subs, foreign_key: 'in_rp_id', class_name: 'Substitute', dependent: :destroy, inverse_of: :in_rp
  has_many :out_subs, foreign_key: 'out_rp_id', class_name: 'Substitute', dependent: :destroy, inverse_of: :out_rp

  delegate :club, :first_name, :fotmob_id, :full_name, :full_name_reverse, :national_team, :name, :position_names,
           :positions, :pseudo_name, :teams, to: :player, allow_nil: true

  default_scope { includes([:tournament_round, { player: %i[club player_positions positions] }]) }

  scope :by_tournament_round, ->(tournament_round_id) { where(tournament_round: tournament_round_id) }
  scope :by_club, ->(club_id) { joins(:player).where(players: { club_id: club_id }) }
  scope :by_national_team, ->(team_id) { joins(:player).where(players: { national_team_id: team_id }) }
  scope :by_name_and_club, ->(name, club_id) { by_club(club_id).where('LOWER(players.name) = ?', name.downcase) }
  scope :with_score, -> { where('score > ?', 0) }
  scope :without_final_score, -> { where(final_score: 0) }
  scope :ordered_by_club, -> { joins(player: :club).order('clubs.name') }
  scope :ordered_by_national, -> { joins(player: :national_team).order('national_teams.id').order('players.name') }

  PC_GOAL_BONUS = 2
  A_GOAL_BONUS = 2.5
  GOAL_BONUS = 3
  CAUGHT_PENALTY_BONUS = 3
  SCORED_PENALTY_BONUS = 2
  ASSIST_BONUS = 1
  POR_CLEANSHEET_BONUS = 1.5
  D_CLEANSHEET_BONUS = 1
  E_M_CLEANSHEET_BONUS = 0.5

  MISSED_GOAL_MALUS = 1.5
  MISSED_PENALTY_MALUS = 1
  FAILED_PENALTY_MALUS = 3
  OWN_GOAL_MALUS = 2
  YELLOW_CARD_MALUS = 0.5
  RED_CARD_MALUS = 2
  POR_RED_CARD_MALUS = 3

  def result_score
    return 0 unless score.positive?
    return final_score unless final_score.zero?

    bonuses - maluses
  end

  def club_played_match?
    TournamentMatch.by_club_and_t_round(club.id, tournament_round.id).first&.host_score.present? ||
      NationalMatch.by_team(national_team&.id).by_t_round(tournament_round.id).first&.host_score.present?
  end

  def another_tournament?
    club.archived? || (club.tournament != tournament_round.tournament)
  end

  def appearances
    match_players.count
  end

  private

  def bonuses
    total = score

    total += goals * goal_bonus if goals
    total += caught_penalty * CAUGHT_PENALTY_BONUS if caught_penalty
    total += scored_penalty * SCORED_PENALTY_BONUS if scored_penalty
    total += assists * ASSIST_BONUS if assists
    total += cleansheet_bonus if cleansheet

    total
  end

  def maluses
    total = 0

    total += missed_goals * MISSED_GOAL_MALUS if missed_goals
    total += missed_penalty * MISSED_PENALTY_MALUS if missed_penalty
    total += failed_penalty * FAILED_PENALTY_MALUS if failed_penalty
    total += own_goals * OWN_GOAL_MALUS if own_goals
    total += YELLOW_CARD_MALUS if yellow_card
    total += red_card_malus if red_card

    total
  end

  def goal_bonus
    if position_names.include?(Position::STRIKER)
      PC_GOAL_BONUS
    elsif position_names.include?(Position::FORWARD)
      A_GOAL_BONUS
    else
      GOAL_BONUS
    end
  end

  def cleansheet_bonus
    return 0 if (position_names & Position::CLEANSHEET_ZONE).blank?

    if position_names.include?(Position::GOALKEEPER)
      POR_CLEANSHEET_BONUS
    elsif (position_names & Position::D_CLEANSHEET_ZONE).any?
      D_CLEANSHEET_BONUS
    elsif (position_names & Position::E_M_CLEANSHEET_ZONE).any?
      E_M_CLEANSHEET_BONUS
    end
  end

  def red_card_malus
    if position_names.include?(Position::GOALKEEPER)
      POR_RED_CARD_MALUS
    else
      RED_CARD_MALUS
    end
  end
end

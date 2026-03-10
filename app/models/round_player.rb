class RoundPlayer < ApplicationRecord
  belongs_to :tournament_round
  belongs_to :player
  belongs_to :club, optional: true

  has_many :match_players, dependent: :destroy
  has_many :lineups, through: :match_players

  has_many :in_subs, foreign_key: 'in_rp_id', class_name: 'Substitute', dependent: :destroy, inverse_of: :in_rp
  has_many :out_subs, foreign_key: 'out_rp_id', class_name: 'Substitute', dependent: :destroy, inverse_of: :out_rp

  delegate :first_name, :fotmob_id, :full_name, :full_name_reverse, :national_team, :name, :position_names,
           :positions, :pseudo_name, :sofascore_id, :teams, to: :player, allow_nil: true

  default_scope { includes([:club, :tournament_round, { player: %i[club player_positions positions] }]) }

  scope :by_tournament_round, ->(tournament_round_id) { where(tournament_round: tournament_round_id) }
  scope :by_club, ->(club_id) { joins(:player).where(players: { club_id: club_id }) }
  scope :by_national_team, ->(team_id) { joins(:player).where(players: { national_team_id: team_id }) }
  scope :by_name_and_club, ->(name, club_id) { by_club(club_id).where('LOWER(players.name) = ?', name.downcase) }
  scope :with_score, -> { where('score > ?', 0) }
  scope :in_squad, -> { where(in_squad: true) }
  scope :without_final_score, -> { where(final_score: 0) }
  scope :ordered_by_club, -> { joins(player: :club).order('clubs.name') }
  scope :ordered_by_national, -> { joins(player: :national_team).order('national_teams.id').order('players.name') }

  STRIKER_GOAL_BONUS = 2
  FORWARD_GOAL_BONUS = 2.5
  GOAL_BONUS = 3
  CAUGHT_PENALTY_BONUS = 3
  SCORED_PENALTY_BONUS = 2
  ASSIST_BONUS = 1
  PENALTY_WON_BONUS = 1
  GK_CLEANSHEET_BONUS = 1.5
  D_CLEANSHEET_BONUS = 1
  E_M_CLEANSHEET_BONUS = 0.5
  UPPER_SAVES_BONUS = 1
  LOWER_SAVES_BONUS = 0.5

  MISSED_GOAL_MALUS = 1
  MISSED_PENALTY_MALUS = 1
  FAILED_PENALTY_MALUS = 2
  CONCEDED_PENALTY_MALUS = 1
  OWN_GOAL_MALUS = 2
  YELLOW_CARD_MALUS = 0.5
  RED_CARD_MALUS = 2
  POR_RED_CARD_MALUS = 3

  UPPER_SAVES_LIMIT = 6
  LOWER_SAVES_LIMIT = 3

  def result_score
    return 0 unless score.positive?

    final_score.positive? ? final_score : bonuses - maluses
  end

  def club_played_match?
    tournament_played? || national_played? || tournament_matches_empty_but_exist?
  end

  def another_tournament?
    player.club.archived? ||
      (player.club.tournament != tournament_round.tournament &&
       player.club.ec_tournament != tournament_round.tournament)
  end

  def appearances
    match_players.count
  end

  def main_appearances
    match_players.main.count
  end

  def related_club
    club || player.club
  end

  private

  def tournament_played?
    tournament_matches_for_club.any? { |m| m.host_score.present? }
  end

  def national_played?
    return false unless national_team

    NationalMatch.by_team(national_team.id).by_t_round(t_round_id).where.not(host_score: nil).exists?
  end

  def tournament_matches_empty_but_exist?
    tournament_matches_for_club.empty? && tournament_round.tournament_matches.exists?
  end

  def tournament_matches_for_club
    @tournament_matches_for_club ||= TournamentMatch.by_club_and_t_round(club_id_to_check, t_round_id).to_a
  end

  def club_id_to_check
    club_id || player.club.id
  end

  def t_round_id
    tournament_round.id
  end

  def bonuses
    total = score

    total += goals * goal_bonus if goals
    total += caught_penalty * CAUGHT_PENALTY_BONUS if caught_penalty
    total += scored_penalty * SCORED_PENALTY_BONUS if scored_penalty
    total += assists * ASSIST_BONUS if assists
    total += penalties_won * PENALTY_WON_BONUS if penalties_won
    total += cleansheet_bonus if cleansheet
    total += saves_bonus if saves

    total
  end

  def maluses
    total = 0

    total += missed_goals * MISSED_GOAL_MALUS if missed_goals
    total += missed_penalty * MISSED_PENALTY_MALUS if missed_penalty
    total += failed_penalty * FAILED_PENALTY_MALUS if failed_penalty
    total += conceded_penalty * CONCEDED_PENALTY_MALUS if conceded_penalty
    total += own_goals * OWN_GOAL_MALUS if own_goals
    total += YELLOW_CARD_MALUS if yellow_card
    total += red_card_malus if red_card

    total
  end

  def goal_bonus
    if position_names.include?(Position::STRIKER)
      STRIKER_GOAL_BONUS
    elsif position_names.include?(Position::FORWARD)
      FORWARD_GOAL_BONUS
    else
      GOAL_BONUS
    end
  end

  def cleansheet_bonus
    return 0 if (position_names & Position::CLEANSHEET_ZONE).blank?

    if position_names.include?(Position::GOALKEEPER)
      GK_CLEANSHEET_BONUS
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

  def saves_bonus
    return 0 if position_names.exclude?(Position::GOALKEEPER) || saves < LOWER_SAVES_LIMIT

    if saves >= UPPER_SAVES_LIMIT
      UPPER_SAVES_BONUS
    else
      LOWER_SAVES_BONUS
    end
  end
end

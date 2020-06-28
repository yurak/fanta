class MatchPlayer < ApplicationRecord
  belongs_to :player
  belongs_to :lineup

  delegate :position_names, :name, :club, :teams, to: :player

  enum subs_status: %i[initial get_out get_in not_in_squad]

  scope :main, -> { where.not(real_position: nil) }
  scope :with_score, -> { where('score > ?', 0) }
  scope :subs, -> { where(real_position: nil) }
  scope :subs_bench, -> { where(real_position: nil).where.not(subs_status: :not_in_squad) }
  scope :without_score, -> { where(score: 0) }
  scope :by_tour, ->(tour_id) { includes(:player).joins(:lineup, :player).where('lineups.tour_id = ?', tour_id) }
  scope :reservists_by_tour, ->(tour_id) { subs.by_tour(tour_id).order('players.club_id') }
  scope :by_name_and_club, ->(name, club_id) { joins(:player).where('players.name = ?', name).where('players.club_id = ?', club_id) }
  scope :defenders, -> { where(real_position: Position::DEFENCE) }
  scope :by_real_position, ->(position) { where("real_position LIKE ?", "%" + position + "%") }

  def team_by(league)
    teams.find_by(league: league)
  end

  def malus
    return 0 if own_position?
  end

  def own_position?
    position_names.include?(real_position)
  end

  def position_malus?
    return false unless real_position

    (real_position.split('/') & position_names).empty?
  end

  def total_score
    return 0 unless score

    total = score

    # bonuses
    total += goals * 3 if goals
    total += caught_penalty * 3 if caught_penalty
    total += scored_penalty * 2 if scored_penalty
    total += assists if assists
    total += 1 if cleansheet

    # maluses
    total -= missed_goals * 2 if missed_goals
    total -= missed_penalty if missed_penalty
    total -= failed_penalty * 3 if failed_penalty
    total -= own_goals * 2 if own_goals
    total -= 0.5 if yellow_card
    total -= 1 if red_card
    total -= position_malus if position_malus
    # total += bonus if bonus

    total
  end

  def available_positions
    real_position.split('/').map { |p| Position::DEPENDENCY[p] }.flatten.uniq
  end
end

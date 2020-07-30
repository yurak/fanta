class MatchPlayer < ApplicationRecord
  belongs_to :round_player
  belongs_to :lineup

  # TODO: should be moved with player association to RoundPlayer model
  delegate :tour, to: :lineup
  delegate :player, :player_score, :result_score, to: :round_player
  # TODO: should be released after migrations release
  # delegate :player, :score, :result_score, :goals, :assists, :missed_goals,
  #          :caught_penalty, :missed_penalty, :scored_penalty, :failed_penalty,
  #          :own_goals, :yellow_card, :red_card, to: :round_player
  delegate :position_names, :name, :club, :teams, to: :player

  enum subs_status: %i[initial get_out get_in not_in_squad]

  scope :main, -> { where.not(real_position: nil) }
  scope :with_score, -> { includes(:round_player).joins(:round_player).where('round_players.score > ?', 0) }
  scope :subs, -> { where(real_position: nil) }
  scope :subs_bench, -> { where(real_position: nil).where.not(subs_status: :not_in_squad) }
  scope :without_score, -> { where(score: 0) }
  scope :by_tour, ->(tour_id) { joins(:lineup).where('lineups.tour_id = ?', tour_id) }
  scope :reservists_by_tour, ->(tour_id) { subs.by_tour(tour_id) }
  scope :defenders, -> { where(real_position: Position::DEFENCE) }
  scope :by_real_position, ->(position) { where('real_position LIKE ?', '%' + position + '%') }

  def team_by(league)
    player.teams.find_by(league: league)
  end

  def malus
    0 if own_position?
  end

  def own_position?
    position_names.include?(real_position)
  end

  def position_malus?
    return false unless real_position

    (real_position.split('/') & position_names).empty?
  end

  def total_score
    return 0 unless player_score

    total = result_score

    # TODO: add ability customize cleansheet value and logic
    total += 1 if cleansheet
    total -= position_malus if position_malus

    total
  end

  def available_positions
    real_position.split('/').map { |p| Position::DEPENDENCY[p] }.flatten.uniq
  end
end

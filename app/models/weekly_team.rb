class WeeklyTeam < ApplicationRecord
  belongs_to :team_module
  belongs_to :season
  belongs_to :tournament, optional: true

  has_many :weekly_team_players, dependent: :destroy

  serialize :round_ids, type: Array, coder: YAML

  enum :mode, { top: 'top', flop: 'flop' }
  enum :source, { round: 'round', season: 'season', avg: 'avg' }, prefix: :source

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :mode, presence: true
  validates :mode, inclusion: { in: %w[top] }, if: :source_avg?
  validates :tournament, presence: true, if: -> { source_season? || source_avg? }

  def self.defence_bonus_for(defender_scores)
    return 0 if defender_scores.empty?

    avg = defender_scores.sum / defender_scores.size.to_f
    return 0 if avg < Lineup::MIN_AVG_DEF_SCORE
    return 5 if avg >= Lineup::MAX_AVG_DEF_SCORE

    (((avg - Lineup::MIN_AVG_DEF_SCORE) / Lineup::DEF_BONUS_STEP) + 1).floor
  end

  def total_score
    weekly_team_players.sum(&:total) + defence_bonus
  end

  def defence_bonus
    return 0 if source_avg?

    WeeklyTeam.defence_bonus_for(defender_base_scores)
  end

  private

  def defender_base_scores
    weekly_team_players.select { |wtp| (wtp.slot.positions & Position::DEFENCE).any? }
                       .map { |wtp| wtp.round_player.score }
  end
end

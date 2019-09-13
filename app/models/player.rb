class Player < ApplicationRecord
  has_and_belongs_to_many :positions
  belongs_to :team
  belongs_to :club

  has_many :match_players, dependent: :destroy
  has_many :lineups, through: :match_players

  scope :by_position, ->(position) { joins(:positions).where(positions: { name: position }) }
  scope :stats_query, ->{ includes(:club, :team, :positions, :match_players).order(:name) }
  enum status: %i[ready problematic injured disqualified]

  scope :order_by_status, -> do
    order_by = ['CASE']
    statuses.values.each_with_index do |status, index|
      order_by << "WHEN status=#{status} THEN #{index}"
    end
    order_by << 'END'
    order(order_by.join(' '))
  end

  def positions_names_string
    position_names.join(' ')
  end

  def position_names
    positions.map(&:name)
  end

  def played_matches_count
    @played_matches_count ||= played_matches.count
  end

  def average_score
    return 0 if played_matches_count.zero?
    @average_score ||= (played_matches.map(&:score).sum / played_matches_count).round(2)
  end

  def average_total_score
    return 0 if played_matches_count.zero?
    @average_total_score ||= (played_matches.map(&:total_score).sum / played_matches_count).round(2)
  end

  private

  def played_matches
    @played_matches ||= match_players.main_with_score
  end
end

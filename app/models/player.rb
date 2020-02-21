class Player < ApplicationRecord
  has_and_belongs_to_many :positions
  belongs_to :club
  # TODO: change to has_and_belongs_to_many :teams
  belongs_to :team, optional: true

  has_many :match_players, dependent: :destroy
  has_many :lineups, through: :match_players

  # TODO: unique by name and club
  # validates :name, uniqueness: true

  scope :by_position, ->(position) { joins(:positions).where(positions: { name: position }) }
  scope :stats_query, -> { includes(:match_players, :club, :team, :positions).order(:name) }

  enum status: %i[ready problematic injured disqualified]

  scope :order_by_status, -> do
    order_by = ['CASE']
    statuses.values.each_with_index do |status, index|
      order_by << "WHEN status=#{status} THEN #{index}"
    end
    order_by << 'END'
    order(order_by.join(' '))
  end

  def avatar_path
    path = "players/#{club.name.downcase}/#{name.downcase.tr(' ', '_').delete("'")}.png"
    ActionController::Base.helpers.resolve_asset_path(path) ? path : 'players/avatar.png'
  end

  def positions_names_string
    position_names.join(' ')
  end

  def position_names
    @position_names ||= positions.map(&:name)
  end

  def position_sequence_number
    positions.first.id
  end

  def played_matches_count
    @played_matches_count ||= played_matches.size
  end

  def scores_count
    @scores_count ||= match_with_scores.size
  end

  def average_score
    return 0 if scores_count.zero?

    @average_score ||= (match_with_scores.map(&:score).sum / scores_count).round(2)
  end

  def average_total_score
    return 0 if scores_count.zero?

    @average_total_score ||= (match_with_scores.map(&:total_score).sum / scores_count).round(2)
  end

  def can_clean_sheet?
    (position_names & Position::DEFENSIVE).any?
  end

  def chart_info
    bs = {}
    ts = {}
    match_players.each do |mp|
      bs[mp.lineup.tour.number] = mp.score
      ts[mp.lineup.tour.number] = mp.total_score
    end
    [{ name: 'Total score', data: ts }, { name: 'Score', data: bs }]
  end

  def best_score
    match_with_scores.map(&:total_score).max || 0
  end

  def worst_score
    match_with_scores.map(&:total_score).min || 0
  end

  private

  def played_matches
    @played_matches ||= match_players.main.with_score
  end

  def match_with_scores
    @match_with_scores ||= match_players.with_score
  end
end

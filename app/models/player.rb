class Player < ApplicationRecord
  belongs_to :club

  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions

  has_many :player_teams, dependent: :destroy
  has_many :teams, through: :player_teams

  has_many :match_players, dependent: :destroy
  has_many :lineups, through: :match_players

  # TODO: add uniqueness validation by name and first_name
  # validates :name, uniqueness: true

  scope :by_position, ->(position) { joins(:positions).where(positions: { name: position }) }
  scope :stats_query, -> { includes(:match_players, :club, :positions).order(:name) }

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
    path = "players/#{path_name}.png"
    ActionController::Base.helpers.resolve_asset_path(path) ? path : 'players/avatar.png'
  end

  def full_name
    first_name ? "#{first_name} #{name}" : name
  end

  def path_name
    full_name.downcase.tr(' ', '_').tr('-', '_').delete("'")
  end

  def kit_path
    "kits/#{club.path_name}.png"
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

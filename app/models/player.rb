class Player < ApplicationRecord
  belongs_to :club

  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions

  has_many :player_teams, dependent: :destroy
  has_many :teams, through: :player_teams

  has_many :match_players, dependent: :destroy
  has_many :lineups, through: :match_players

  validates :name, uniqueness: { scope: :first_name }
  validates :name, presence: true

  scope :by_position, ->(position) { joins(:positions).where(positions: { name: position }) }
  scope :stats_query, -> { includes(:match_players, :club, :positions).order(:name) }

  # TODO: move statuses to MatchPlayer model
  enum status: %i[ready problematic injured disqualified]
  scope :order_by_status, lambda {
    order_by = ['CASE']
    statuses.values.each_with_index do |status, index|
      order_by << "WHEN status=#{status} THEN #{index}"
    end
    order_by << 'END'
    order(order_by.join(' '))
  }

  def avatar_path
    path = "players/#{path_name}.png"
    ActionController::Base.helpers.resolve_asset_path(path) ? path : 'players/avatar.png'
  end

  def full_name
    first_name ? "#{first_name} #{name}" : name
  end

  def pseudo_name
    pseudonym.empty? ? full_name : pseudonym
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

  def can_clean_sheet?
    (position_names & Position::DEFENSIVE).any?
  end

  def played_matches_count
    # TODO: use matches played for team
    @played_matches_count ||= played_matches.size
  end

  def scores_count
    # TODO: use matches played for team
    @scores_count ||= match_with_scores.size
  end

  def average_score
    # TODO: use matches played for team
    return 0 if scores_count.zero?

    @average_score ||= (match_with_scores.map(&:score).sum / scores_count).round(2)
  end

  def average_total_score
    # TODO: use matches played for team
    return 0 if scores_count.zero?

    @average_total_score ||= (match_with_scores.map(&:total_score).sum / scores_count).round(2)
  end

  def chart_info
    # TODO: use matches played for team
    bs = {}
    ts = {}
    match_players.each do |mp|
      bs[mp.lineup.tour.number] = mp.score
      ts[mp.lineup.tour.number] = mp.total_score
    end
    [{ name: 'Total score', data: ts }, { name: 'Score', data: bs }]
  end

  def best_score
    # TODO: use matches played for team
    match_with_scores.map(&:total_score).max || 0
  end

  def worst_score
    # TODO: use matches played for team
    match_with_scores.map(&:total_score).min || 0
  end

  private

  def played_matches
    # TODO: use matches played for team
    @played_matches ||= match_players.main.with_score
  end

  def match_with_scores
    # TODO: use matches played for team
    @match_with_scores ||= match_players.with_score
  end
end

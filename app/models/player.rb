class Player < ApplicationRecord
  belongs_to :club

  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions

  has_many :player_teams, dependent: :destroy
  has_many :teams, through: :player_teams

  has_many :round_players, dependent: :destroy

  BUCKET_URL = 'https://mantra-players.s3-eu-west-1.amazonaws.com'.freeze

  validates :name, uniqueness: { scope: :first_name }
  validates :name, presence: true

  scope :by_club, ->(club_id) { where(club_id: club_id) }
  scope :by_position, ->(position) { joins(:positions).where(positions: { name: position }) }
  scope :by_tournament, ->(tournament_id) { joins(:club).where(clubs: { tournament: tournament_id, status: 'active' }) }
  scope :stats_query, -> { includes(:club, :positions).order(:name) }
  scope :with_team, -> { includes(:teams).where.not(teams: { id: nil }) }

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
    # path = "players/#{path_name}.png"
    # ActionController::Base.helpers.resolve_asset_path(path) ? path : 'avatar.png'
    "#{BUCKET_URL}/#{path_name}.png"
  end

  def country
    case nationality
    when 'gb-eng' then 'England'
    when 'gb-wls' then 'Wales'
    when 'gb-sct' then 'Scotland'
    when 'gb-nir' then 'Northern Ireland'
    else ISO3166::Country.new(nationality).name
    end
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
    (position_names & Position::CLEANSHEET_ZONE).any?
  end

  # def played_matches_count
  #   # TODO: use matches played for team
  #   @played_matches_count ||= played_matches.size
  # end

  def scores_count
    @scores_count ||= matches_with_scores.size
  end

  def average_score
    return 0 if scores_count.zero?

    @average_score ||= (matches_with_scores.map(&:score).sum / scores_count).round(2)
  end

  def average_result_score
    return 0 if scores_count.zero?

    @average_result_score ||= (matches_with_scores.map(&:result_score).sum / scores_count).round(2)
  end

  def chart_info
    bs = {}
    ts = {}
    round_players.each do |rp|
      bs[rp.lineup.tour.number] = rp.score
      ts[rp.lineup.tour.number] = rp.result_score
    end
    [{ name: 'Total score', data: ts }, { name: 'Score', data: bs }]
  end

  def best_score
    matches_with_scores.map(&:result_score).max || 0
  end

  def worst_score
    matches_with_scores.map(&:result_score).min || 0
  end

  private

  # def played_matches
  #   # TODO: use matches played for team
  #   @played_matches ||= match_players.main.with_score
  # end

  def matches_with_scores
    @matches_with_scores ||= round_players.with_score
  end
end

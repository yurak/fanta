class Player < ApplicationRecord
  belongs_to :club

  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions

  has_many :player_teams, dependent: :destroy
  has_many :teams, through: :player_teams

  has_many :round_players, dependent: :destroy

  BUCKET_URL = 'https://mantrafootball.s3-eu-west-1.amazonaws.com'.freeze

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
    "#{BUCKET_URL}/player_avatars/#{path_name}.png"
  end

  def profile_avatar_path
    "#{BUCKET_URL}/players/#{path_name}.png"
  end

  def country
    case nationality
    when 'gb-eng' then 'England'
    when 'gb-wls' then 'Wales'
    when 'gb-sct' then 'Scotland'
    when 'gb-nir' then 'Northern Ireland'
    else ISO3166::Country.new(nationality)&.name
    end
  end

  def full_name
    first_name ? "#{first_name} #{name}" : name
  end

  def full_name_reverse
    first_name ? "#{name} #{first_name}" : name
  end

  def pseudo_name
    pseudonym.empty? ? full_name : pseudonym
  end

  def path_name
    full_name.downcase.tr(' ', '_').tr('-', '_').delete("'")
  end

  def kit_path
    "kits/kits_small/#{club.path_name}.png"
  end

  def profile_kit_path
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
    season_matches_with_scores.each do |rp|
      bs[rp.tournament_round.number] = rp.score
      ts[rp.tournament_round.number] = rp.result_score
    end
    [{ name: 'Total score', data: ts }, { name: 'Base score', data: bs }]
  end

  def best_score
    matches_with_scores.map(&:result_score).max || 0
  end

  def worst_score
    matches_with_scores.map(&:result_score).min || 0
  end

  # Current season statistic

  def season_scores_count
    @season_scores_count ||= season_matches_with_scores.size
  end

  def season_average_score
    return 0 if season_scores_count.zero?

    @season_average_score ||= (season_matches_with_scores.map(&:score).sum / season_scores_count).round(2)
  end

  def season_average_result_score
    return 0 if season_scores_count.zero?

    @season_average_result_score ||= (season_matches_with_scores.map(&:result_score).sum / season_scores_count).round(2)
  end

  def season_matches_with_scores
    @season_matches_with_scores ||= round_players.with_score.by_tournament_round(Season.last.tournament_rounds)
  end

  def season_bonus_count(bonus)
    season_matches_with_scores.map(&bonus.to_sym).sum.to_i
  end

  def season_cards_count(card)
    season_matches_with_scores.where(card => true).count
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

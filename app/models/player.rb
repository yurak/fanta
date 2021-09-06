class Player < ApplicationRecord
  belongs_to :club
  belongs_to :national_team, optional: true

  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions

  has_many :player_teams, dependent: :destroy
  has_many :teams, through: :player_teams

  has_many :round_players, dependent: :destroy
  has_many :transfers, dependent: :destroy

  CONTENT_TYPE_PNG = 'image/png'.freeze
  BUCKET_URL = 'https://mantrafootball.s3-eu-west-1.amazonaws.com'.freeze

  validates :name, uniqueness: { scope: %i[first_name tm_url] }, presence: true

  scope :by_club, ->(club_id) { where(club_id: club_id) }
  scope :search_by_name, ->(search_str) { where('lower(name) LIKE :search OR lower(first_name) LIKE :search', search: "%#{search_str}%") }
  scope :by_position, ->(position) { joins(:positions).where(positions: { name: position }) }
  scope :by_tournament, ->(tournament) { where(club: tournament.clubs.active) }
  scope :by_ec_tournament, ->(tournament) { where(club: tournament.ec_clubs.active) }
  scope :by_national_tournament, ->(tment_id) { joins(:national_team).where(national_teams: { tournament: tment_id, status: 'active' }) }
  scope :by_national_teams, ->(nt_id) { where(national_team_id: nt_id) }
  scope :by_national_tournament_round, ->(tr) { by_national_teams(tr.national_matches.pluck(:host_team_id, :guest_team_id).reduce([], :+)) }
  scope :by_tournament_round, ->(tr) { by_club(tr.tournament_matches.pluck(:host_club_id, :guest_club_id).reduce([], :+)) }
  scope :stats_query, -> { includes(:club, :positions).order(:name) }
  scope :with_team, -> { includes(:teams).where.not(teams: { id: nil }) }

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

  def national_kit_path
    "#{BUCKET_URL}/kits/national_small/#{national_team.code}.png" if national_team
  end

  def profile_national_kit_path
    "#{BUCKET_URL}/kits/national/#{national_team.code}.png" if national_team
  end

  def kit_path
    "#{BUCKET_URL}/kits/club_small/#{club.path_name}.png"
  end

  def profile_kit_path
    "#{BUCKET_URL}/kits/club/#{club.path_name}.png"
  end

  def position_names
    @position_names ||= positions.map(&:name)
  end

  def position_sequence_number
    positions.first&.id
  end

  def transfer_by(team)
    transfers.incoming.where(team: team).last
  end

  # Current season statistic

  def chart_info
    bs = {}
    ts = {}
    season_matches_with_scores.each do |rp|
      bs[rp.tournament_round.number] = rp.score.to_s
      ts[rp.tournament_round.number] = rp.result_score.to_s
    end
    [{ name: 'Total score', data: ts }, { name: 'Base score', data: bs }]
  end

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
    @season_matches_with_scores ||= round_players.with_score.by_tournament_round(season_club_tournament_rounds).order(:tournament_round_id)
  end

  def season_bonus_count(bonus)
    season_matches_with_scores.map(&bonus.to_sym).sum.to_i
  end

  def season_cards_count(card)
    return 0 unless season_matches_with_scores.any?

    season_matches_with_scores.where(card => true).count
  end

  def season_played_minutes
    return 0 unless season_matches_with_scores.any?

    @season_played_minutes ||= season_matches_with_scores.map(&:played_minutes).sum
  end

  # NationalTeams Tournament statistic

  def national_scores_count
    @national_scores_count ||= national_matches_with_scores.size
  end

  def national_average_score
    return 0 if national_scores_count.zero?

    @national_average_score ||= (national_matches_with_scores.map(&:score).sum / national_scores_count).round(2)
  end

  def national_average_result_score
    return 0 if national_scores_count.zero?

    @national_average_result_score ||= (national_matches_with_scores.map(&:result_score).sum / national_scores_count).round(2)
  end

  def national_matches_with_scores
    return [] unless national_team

    @national_matches_with_scores ||= round_players.with_score
                                                   .by_tournament_round(Tournament.with_national_teams.last&.tournament_rounds)
                                                   .order(:tournament_round_id)
  end

  def national_bonus_count(bonus)
    national_matches_with_scores.map(&bonus.to_sym).sum.to_i
  end

  def national_cards_count(card)
    return 0 unless national_matches_with_scores.any?

    national_matches_with_scores.where(card => true).count
  end

  def age
    return if birth_date.empty?

    (Time.zone.today.strftime('%Y%m%d').to_i - birth_date.to_date.strftime('%Y%m%d').to_i) / 10_000
  end

  def team_by_league(league_id)
    teams.find_by(league_id: league_id)
  end

  private

  def season_club_tournament_rounds
    return [] unless club.tournament

    TournamentRound.by_tournament(club.tournament.id).by_season(Season.last.id)
  end
end

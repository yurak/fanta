class Player < ApplicationRecord
  belongs_to :club
  belongs_to :national_team, optional: true

  has_many :player_positions, -> { order(:position_id) }, dependent: :destroy, inverse_of: :player
  has_many :positions, -> { order(:id) }, through: :player_positions

  has_many :player_teams, dependent: :destroy
  has_many :teams, through: :player_teams

  has_many :player_bids, dependent: :destroy
  has_many :player_requests, dependent: :destroy
  has_many :player_season_stats, dependent: :destroy
  has_many :round_players, dependent: :destroy
  has_many :transfers, dependent: :destroy
  has_many :club_transfers, dependent: :destroy

  include SeasonStats

  BUCKET_URL = Rails.application.credentials.aws[:bucket_url].freeze
  TM_PATH = 'https://www.transfermarkt.com/player-path/profil/spieler/'.freeze
  NEWBIE_PERIOD = 3.months

  normalizes :avatar_name, with: ->(avatar_name) { avatar_name.strip.presence }

  validates :name, presence: true
  validates :tm_id, uniqueness: true, allow_nil: true
  validates :fotmob_id, uniqueness: true, allow_nil: true
  validates :sofascore_id, uniqueness: true, allow_nil: true

  delegate :kit_path, :profile_kit_path, to: :club

  COUNTRY = {
    bo: 'Bolivia',
    bq: 'Bonaire',
    ba: 'Bosnia-Herzegovina',
    cd: 'DR Congo',
    cv: 'Cape Verde',
    cz: 'Czech Republic',
    'gb-eng': 'England',
    'gb-wls': 'Wales',
    'gb-sct': 'Scotland',
    'gb-nir': 'Northern Ireland',
    gm: 'The Gambia',
    ir: 'Iran',
    kr: 'Korea, South',
    kn: 'St. Kitts & Nevis',
    lc: 'St. Lucia',
    md: 'Moldova',
    ps: 'Palestine',
    ru: 'terrorist state',
    sy: 'Syria',
    tz: 'Tanzania',
    us: 'United States',
    ve: 'Venezuela',
    xk: 'Kosovo'
  }.freeze

  scope :by_club, ->(club_id) { where(club_id: club_id) if club_id.present? }
  scope :search_by_name, lambda { |search_str|
    where('lower(players.name) LIKE :search OR lower(players.first_name) LIKE :search', search: "%#{search_str.downcase}%")
  }
  scope :by_position, ->(position) { joins(:positions).where(positions: { name: position }) if position.present? }
  scope :by_classic_position, ->(position) { joins(:positions).where(positions: { human_name: position }) if position.present? }
  scope :by_tournament, ->(tournament) { where(club: tournament.clubs.active) if tournament.present? }
  scope :by_ec_tournament, ->(tournament) { where(club: tournament.ec_clubs.active) }
  scope :by_national_tournament, ->(tment_id) { joins(:national_team).where(national_teams: { tournament: tment_id, status: 'active' }) }
  scope :by_national_teams, ->(nt_id) { where(national_team_id: nt_id) }
  scope :by_national_tournament_round, ->(tr) { by_national_teams(tr.national_matches.pluck(:host_team_id, :guest_team_id).reduce([], :+)) }
  scope :by_tournament_round, ->(tr) { by_club(tr.tournament_matches.pluck(:host_club_id, :guest_club_id).reduce([], :+)) }
  scope :stats_query, -> { includes(:club, :positions).order(:name) }
  scope :with_team, -> { includes(:teams).where.not(teams: { id: nil }) }
  scope :with_admin_includes, -> { includes(:positions, :teams) }

  def avatar_path
    "#{BUCKET_URL}/player_avatars/#{path_name}.png"
  end

  def profile_avatar_path
    "#{BUCKET_URL}/players/#{path_name}.png"
  end

  def country
    return '' unless nationality

    COUNTRY[nationality.to_sym] || ISO3166::Country.new(nationality)&.iso_short_name
  end

  def full_name
    first_name ? "#{first_name} #{name}" : name
  end

  def newbie?
    current_club_joins.any? { |transfer| new_club?(transfer) }
  end

  def full_name_reverse
    first_name ? "#{name} #{first_name}" : name
  end

  def full_name_with_positions
    "#{full_name} (#{position_names.join(' ')})"
  end

  def pseudo_name
    pseudonym.empty? ? full_name : pseudonym
  end

  def path_name
    @path_name ||= avatar_name || full_name.downcase.tr(' ', '_').tr('-', '_').delete("'")
  end

  def national_kit_path
    national_team&.kit_path || NationalTeam.find_by(code: nationality)&.kit_path
  end

  def profile_national_kit_path
    national_team&.profile_kit_path
  end

  def tm_path
    return '' unless tm_id

    "#{TM_PATH}#{tm_id}"
  end

  def tm_position_path(season_start_year)
    return '' unless tm_id

    "https://www.transfermarkt.com/player-path/leistungsdaten/spieler/#{tm_id}/plus/0?saison=#{season_start_year}"
  end

  def position_names
    @position_names ||= positions.map(&:name)
  end

  def position_sequence_number
    positions.first&.id || Float::INFINITY
  end

  def transfer_by(team)
    transfers.select { |t| t.incoming? && t.team_id == team.id }.last
  end

  def current_average_price
    return 0 if teams.blank?

    (teams.map { |team| transfer_by(team)&.price || 0 }.sum(0.0) / teams.count).round(1)
  end

  def age
    return if birth_date.empty?

    (Time.zone.today.strftime('%Y%m%d').to_i - birth_date.to_date.strftime('%Y%m%d').to_i) / 10_000
  end

  def team_by_league(league_id)
    return teams.find { |t| t.league_id == league_id.to_i } if teams.loaded?

    teams.find_by(league_id: league_id)
  end

  def stats_price
    @stats_price ||= player_season_stats.where(season: Season.second_to_last, tournament: club.tournament).last&.position_price || 1
  end

  def player_bids_by(auction_id)
    player_bids
      .joins('INNER JOIN auction_bids ON player_bids.auction_bid_id = auction_bids.id')
      .joins('INNER JOIN auction_rounds ON auction_bids.auction_round_id = auction_rounds.id')
      .joins('INNER JOIN auctions ON auction_rounds.auction_id = auctions.id')
      .includes(auction_bid: %i[auction_round team])
      .where(auctions: { id: auction_id })
      .order('player_bids.price DESC')
      .group_by { |bid| bid.auction_bid.auction_round.number }
      .sort_by { |round_number, _| round_number }.reverse.to_h
  end

  private

  def current_club_joins
    club_transfers.select do |transfer|
      transfer.start_date&.between?(NEWBIE_PERIOD.ago.to_date, Time.zone.today) && current_club?(transfer)
    end
  end

  def current_club?(transfer)
    transfer.new_club_id == club_id || (transfer.new_club_id.nil? && transfer.new_club_name == club&.name)
  end

  def new_club?(transfer)
    key = transfer.new_club_id || transfer.new_club_name
    return false if key.blank?

    club_transfers.none? { |other| recent_return?(other, transfer, key) }
  end

  def recent_return?(other, transfer, key)
    return false if other.equal?(transfer) || other.start_date.nil?
    return false unless other.start_date <= transfer.start_date
    return false if other.start_date < transfer.start_date - NEWBIE_PERIOD

    [other.new_club_id || other.new_club_name, other.old_club_id || other.old_club_name].include?(key)
  end
end

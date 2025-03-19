class Player < ApplicationRecord
  belongs_to :club
  belongs_to :national_team, optional: true

  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions

  has_many :player_teams, dependent: :destroy
  has_many :teams, through: :player_teams

  has_many :player_bids, dependent: :destroy
  has_many :player_requests, dependent: :destroy
  has_many :player_season_stats, dependent: :destroy
  has_many :round_players, dependent: :destroy
  has_many :transfers, dependent: :destroy

  BUCKET_URL = 'https://mantrafootball.s3-eu-west-1.amazonaws.com'.freeze
  TM_PATH = 'https://www.transfermarkt.com/player-path/profil/spieler/'.freeze

  validates :name, presence: true
  validates :tm_id, uniqueness: true, allow_nil: true
  validates :fotmob_id, uniqueness: true, allow_nil: true

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

  COUNTRY = {
    bo: 'Bolivia',
    cd: 'DR Congo',
    'gb-eng': 'England',
    'gb-wls': 'Wales',
    'gb-sct': 'Scotland',
    'gb-nir': 'Northern Ireland',
    ir: 'Iran',
    kr: 'Korea',
    md: 'Moldova',
    ps: 'Palestine',
    ru: 'terrorist state',
    sy: 'Syria',
    tz: 'Tanzania',
    us: 'USA',
    ve: 'Venezuela',
    xk: 'Kosovo'
  }.freeze

  scope :by_club, ->(club_id) { where(club_id: club_id) if club_id.present? }
  scope :search_by_name, lambda { |search_str|
    where('lower(players.name) LIKE :search OR lower(players.first_name) LIKE :search', search: "%#{search_str}%")
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
    positions.first&.id
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

  # Current season statistic

  def chart_info(matches)
    bs = {}
    ts = {}
    matches.each do |rp|
      bs[rp.tournament_round.number] = rp.score.to_s
      ts[rp.tournament_round.number] = rp.result_score.to_s
    end
    [{ name: 'Total score', data: ts }, { name: 'Base score', data: bs }]
  end

  def season_matches_with_scores
    @season_matches_with_scores ||= round_players.with_score.by_tournament_round(club_tournament_season_rounds)
  end

  def season_matches
    @season_matches ||= round_players.by_tournament_round(club_tournament_season_rounds)
  end

  def season_club_matches_w_scores
    @season_club_matches_w_scores ||= round_players.with_score.by_tournament_round(season_tournament_rounds)
  end

  def season_club_in_squad
    @season_club_in_squad ||= round_players.in_squad.by_tournament_round(season_tournament_rounds)
  end

  def season_ec_matches_with_scores
    @season_ec_matches_with_scores ||= round_players.with_score.by_tournament_round(season_club_eurocup_rounds).order(:tournament_round_id)
  end

  def season_ec_in_squad
    @season_ec_in_squad ||= round_players.in_squad.by_tournament_round(season_club_eurocup_rounds).order(:tournament_round_id)
  end

  def season_all_matches_with_scores
    @season_all_matches_with_scores ||= round_players.with_score.by_tournament_round(season_all_tournam_rounds).order(:tournament_round_id)
  end

  def national_matches_with_scores
    @national_matches_with_scores ||= round_players.with_score.by_tournament_round(national_team_rounds).order(:tournament_round_id)
  end

  def national_in_squad
    @national_in_squad ||= round_players.in_squad.by_tournament_round(national_team_rounds).order(:tournament_round_id)
  end

  def season_scores_count(matches = season_matches_with_scores)
    matches.size
  end

  def season_average_score(matches = season_matches_with_scores)
    return 0 if season_scores_count(matches).zero?

    (matches.map(&:score).sum / season_scores_count(matches)).round(2)
  end

  def season_average_result_score(matches = season_matches_with_scores)
    return 0 if season_scores_count(matches).zero?

    (matches.map(&:result_score).sum / season_scores_count(matches)).round(2)
  end

  def season_bonus_count(matches, bonus)
    return 0 unless matches.any?

    matches.map(&bonus.to_sym).sum.to_i
  end

  def season_cards_count(matches, card)
    return 0 unless matches.any?

    matches.where(card => true).count
  end

  def season_played_minutes(matches = season_matches_with_scores)
    return 0 unless matches.any?

    matches.map(&:played_minutes).sum
  end

  def sixty_minutes_plus(matches = season_matches_with_scores)
    matches.where('played_minutes >= ?', MatchPlayer::MIN_PLAYED_MINUTES_FOR_CS).count
  end

  private

  def current_season
    @current_season ||= Season.last
  end

  # all TournamentRound in current tournament for this season
  def club_tournament_season_rounds
    @club_tournament_season_rounds ||=
      club.tournament ? TournamentRound.by_tournament(club.tournament.id).by_season(current_season.id) : []
  end

  # all TournamentRound for this season
  def season_tournament_rounds
    @season_tournament_rounds ||=
      TournamentRound.by_tournament(Tournament.with_clubs).by_season(current_season.id).order(deadline: :desc)
  end

  def season_club_eurocup_rounds
    @season_club_eurocup_rounds ||=
      TournamentRound.by_tournament(Tournament.with_ec_clubs).by_season(current_season.id)
  end

  def season_all_tournam_rounds
    season_tournament_rounds + season_club_eurocup_rounds
  end

  def national_team_rounds
    return [] unless national_team&.tournament

    @national_team_rounds ||= national_team.tournament.tournament_rounds.by_season(current_season.id)
  end
end

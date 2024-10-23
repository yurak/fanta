class Team < ApplicationRecord
  belongs_to :league, optional: true
  belongs_to :user, optional: true

  has_many :auction_bids, dependent: :destroy
  has_many :player_teams, dependent: :destroy
  has_many :players, through: :player_teams

  has_many :lineups, -> { order('tour_id desc') }, dependent: :destroy, inverse_of: :team

  has_many :host_matches, foreign_key: 'host_id', class_name: 'Match', dependent: :destroy, inverse_of: :host
  has_many :guest_matches, foreign_key: 'guest_id', class_name: 'Match', dependent: :destroy, inverse_of: :guest

  has_many :results, dependent: :destroy
  has_many :transfers, dependent: :destroy

  delegate :tournament, to: :league

  MAX_PLAYERS = 26
  MIN_GK = 3
  DEFAULT_BUDGET = 260
  TRANSFER_SLOTS = 16
  RESERVE_TRANSFER_SLOTS = [0, 2, 4, 6, 8, 10].freeze

  validates :name, presence: true, length: { in: 2..18 }
  validates :code, presence: true, length: { in: 2..3 }
  validates :human_name, length: { in: 2..24 }

  default_scope { includes(%i[league user]) }

  scope :by_tournament, ->(tournament_id) { joins(:league).where(leagues: { tournament_id: tournament_id }) }

  def reset
    players.clear
    update(budget: DEFAULT_BUDGET, transfer_slots: TRANSFER_SLOTS)
  end

  def league_matches
    @league_matches ||= matches.by_league(league&.id)
  end

  def league_transfers
    @league_transfers ||= transfers.by_league(league&.id)
  end

  def logo_path
    logo_url.presence || ActionController::Base.helpers.asset_path('default_logo.png')
  end

  def next_round
    return unless league

    @next_round ||= league.active_tour || league.tours.inactive.first
  end

  def opponent_by_match(match)
    match.host == self ? match.guest : match.host
  end

  def next_match
    return unless next_round

    @next_match ||= Match.by_team_and_tour(id, next_round.id).first
  end

  def next_opponent
    return unless next_match

    next_match.host == self ? next_match.guest : next_match.host
  end

  def players_not_in(lineup)
    return unless lineup

    lineup_players_ids = lineup.round_players.map { |rp| rp.player.id }
    not_played_ids = players.where.not(id: lineup_players_ids).ids
    RoundPlayer.by_tournament_round(lineup.tournament_round.id).where(player_id: not_played_ids)
  end

  def best_lineup
    lineups.by_league(league.id).max_by(&:total_score)
  end

  def vacancies
    MAX_PLAYERS - players.count
  end

  def vacancies?
    !full_squad?
  end

  def full_squad?
    vacancies.zero?
  end

  def max_rate
    return 0 if vacancies <= 0

    budget - vacancies + 1
  end

  def sales_period?
    return false unless league

    league.auctions.sales.any?
  end

  def available_transfers
    return 0 if transfer_slots.zero?
    return 0 unless sales_auction

    transfer_slots - RESERVE_TRANSFER_SLOTS[league.auction_number - sales_auction.number]
  end

  def prepared_sales_count
    return 0 unless current_auction

    player_teams.transferable.count + transfers.outgoing.by_auction(current_auction.id).count
  end

  def spent_budget(auction)
    return 0 unless auction

    transfers.incoming.by_auction(auction).sum(&:price)
  end

  def dumped_player_ids(auction)
    transfers.outgoing.by_auction(auction).pluck(:player_id)
  end

  def avg_ts
    return 0 if league_lineups_number.zero?
    return 0 unless league_result

    (results.by_league(league.id).last.total_score / league_lineups_number).round(2)
  end

  def avg_points
    return 0 if league_lineups_number.zero?
    return 0 unless league_result

    (results.by_league(league.id).last.points.to_f / league_lineups_number).round(2)
  end

  def league_lineups_number
    @league_lineups_number ||= league_lineups.size
  end

  def league_lineups
    @league_lineups ||= lineups.by_league(league.id)
  end

  def league_result
    @league_result ||= results.by_league(league.id).last
  end

  private

  def matches
    @matches ||= Match.where('host_id = ? OR guest_id = ?', id, id)
  end

  def current_auction
    @current_auction ||= league.auctions.initial_sales.first
  end

  def sales_auction
    @sales_auction ||= league.auctions.sales.first
  end
end

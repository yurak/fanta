class Team < ApplicationRecord
  belongs_to :league
  belongs_to :user, optional: true

  has_many :player_teams, dependent: :destroy
  has_many :players, through: :player_teams

  has_many :lineups, -> { order('tour_id desc') }, dependent: :destroy, inverse_of: :team

  has_many :host_matches, foreign_key: 'host_id', class_name: 'Match', dependent: :destroy, inverse_of: :host
  has_many :guest_matches, foreign_key: 'guest_id', class_name: 'Match', dependent: :destroy, inverse_of: :guest

  has_many :results, dependent: :destroy
  has_many :transfers, dependent: :destroy

  delegate :tournament, to: :league

  MAX_PLAYERS = 25

  validates :name, presence: true, uniqueness: true, length: { in: 2..18 }
  validates :code, presence: true, uniqueness: true, length: { in: 2..4 }
  validates :human_name, length: { in: 2..18 }

  default_scope { includes(%i[league user]) }

  def league_matches
    @league_matches ||= matches.by_league(league.id)
  end

  def logo_path
    logo_url.presence || 'default_logo.png'
  end

  def next_round
    league.active_tour || league.tours.inactive.first
  end

  def opponent_by_match(match)
    match.host == self ? match.guest : match.host
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

  def max_rate
    return 0 if vacancies <= 0

    budget - vacancies + 1
  end

  private

  def next_match
    return unless next_round

    @next_match ||= Match.by_team_and_tour(id, next_round.id).first
  end

  def matches
    @matches ||= Match.where('host_id = ? OR guest_id = ?', id, id)
  end
end

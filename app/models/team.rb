class Team < ApplicationRecord
  belongs_to :league
  belongs_to :user, optional: true

  has_many :player_teams, dependent: :destroy
  has_many :players, through: :player_teams

  has_many :lineups, -> { order('tour_id desc') }, dependent: :destroy

  has_many :host_matches, foreign_key: 'host_id', class_name: 'Match', dependent: :destroy
  has_many :guest_matches, foreign_key: 'guest_id', class_name: 'Match', dependent: :destroy

  has_many :results, dependent: :destroy

  validates :name, uniqueness: true, length: { in: 2..18 }
  validates :code, uniqueness: true, length: { in: 2..3 }, allow_blank: true
  validates :human_name, length: { in: 2..18 }

  def matches
    @matches ||= Match.where('host_id = ? OR guest_id = ?', id, id)
  end

  def league_matches
    @league_matches ||= matches.by_league(league.id)
  end

  def logo_path
    if File.exist?("app/assets/images/teams/#{name}.png")
      "teams/#{name}.png"
    else
      'teams/default_logo.png'
    end
  end

  def code_name
    (code || human_name[0..2]).upcase
  end

  def next_round
    league.active_tour || league.tours.inactive.first
  end

  def next_match
    return unless next_round

    @next_match ||= Match.by_team_and_tour(id, next_round.id).first
  end

  def opponent_by_match(match)
    match.host == self ? match.guest : match.host
  end

  def next_opponent
    return unless next_match

    next_match.host == self ? next_match.guest : next_match.host
  end

  def players_not_in(lineup)
    lineup_players_ids = lineup.round_players.map { |rp| rp.player.id }
    players.where.not(id: lineup_players_ids)
  end
end

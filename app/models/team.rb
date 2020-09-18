class Team < ApplicationRecord
  belongs_to :league
  belongs_to :user, optional: true

  has_many :player_teams, dependent: :destroy
  has_many :players, through: :player_teams

  has_many :lineups, -> { order('tour_id desc') }, dependent: :destroy

  has_many :host_matches, foreign_key: 'host_id', class_name: 'Match', dependent: :destroy
  has_many :guest_matches, foreign_key: 'guest_id', class_name: 'Match', dependent: :destroy

  has_many :result, dependent: :destroy

  validates :name, uniqueness: true, length: { in: 2..20 }

  def matches
    @matches ||= Match.where('host_id = ? OR guest_id = ?', id, id)
  end

  def logo_path
    if File.exist?("app/assets/images/teams/#{name}.png")
      "teams/#{name}.png"
    else
      'teams/default_logo.png'
    end
  end

  def code_name
    # TODO: add 'code' field to team
    # code || human_name[0..2]
    human_name[0..2]
  end

  def human_name
    name.humanize.upcase
  end

  def next_round
    league.active_tour || league.tours.inactive.first
  end

  def next_match
    @match ||= Match.by_team_and_tour(id, next_round.id).first
  end

  def next_opponent
    next_match.host == self ? next_match.guest : next_match.host
  end
end

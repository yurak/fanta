class Club < ApplicationRecord
  belongs_to :tournament, optional: true
  belongs_to :ec_tournament, optional: true, class_name: 'Tournament'

  has_many :players, dependent: :destroy
  has_many :player_season_stats, dependent: :destroy
  has_many :host_tournament_matches, foreign_key: 'host_club_id', class_name: 'TournamentMatch',
                                     dependent: :destroy, inverse_of: :host_club
  has_many :guest_tournament_matches, foreign_key: 'guest_club_id', class_name: 'TournamentMatch',
                                      dependent: :destroy, inverse_of: :guest_club

  serialize :reserve_clubs, type: Array, coder: YAML
  serialize :reserve_club_ids, type: Array, coder: YAML

  enum status: { active: 0, archived: 1 }

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  scope :order_by_players_count, -> { includes(:players).left_joins(:players).group(:id).order(Arel.sql('COUNT(players.id) DESC')) }
  scope :by_tournament, ->(tournament_id) { where(tournament_id: tournament_id) if tournament_id.present? }

  RETIRED = 'Retired'.freeze

  def logo_path
    "#{Player::BUCKET_URL}/club_logo/#{path_name}.png"
  end

  def kit_path
    "#{Player::BUCKET_URL}/kits/club_small/#{path_name}.png"
  end

  def profile_kit_path
    "#{Player::BUCKET_URL}/kits/club/#{path_name}.png"
  end

  def path_name
    name.downcase.tr(' ', '_')
  end

  def tm_id
    tm_url&.split('/')&.last
  end

  def opponent_by_round(tournament_round)
    matches = tournament_round.tournament_matches.to_a
    host_match = matches.find { |m| m.host_club_id == id }
    return host_match.guest_club if host_match

    guest_match = matches.find { |m| m.guest_club_id == id }
    guest_match&.host_club
  end

  def match_host?(tournament_round)
    tournament_round.tournament_matches.to_a.any? { |m| m.host_club_id == id }
  end
end

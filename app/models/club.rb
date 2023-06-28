class Club < ApplicationRecord
  belongs_to :tournament, optional: true
  belongs_to :ec_tournament, optional: true, class_name: 'Tournament'

  has_many :players, dependent: :destroy
  has_many :player_season_stats, dependent: :destroy
  has_many :host_tournament_matches, foreign_key: 'host_club_id', class_name: 'TournamentMatch',
                                     dependent: :destroy, inverse_of: :host_club
  has_many :guest_tournament_matches, foreign_key: 'guest_club_id', class_name: 'TournamentMatch',
                                      dependent: :destroy, inverse_of: :guest_club

  enum status: { active: 0, archived: 1 }

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  default_scope { includes(:tournament) }

  scope :order_by_players_count, -> { includes(:players).left_joins(:players).group(:id).order(Arel.sql('COUNT(players.id) DESC')) }

  def logo_path
    "#{Player::BUCKET_URL}/club_logo/#{path_name}.png"
  end

  def path_name
    name.downcase.tr(' ', '_')
  end

  def opponent_by_round(tournament_round)
    match = host_tournament_matches.find_by(tournament_round: tournament_round)

    if match
      opponent = match&.guest_club
    else
      match = guest_tournament_matches.find_by(tournament_round: tournament_round)
      opponent = match&.host_club
    end

    opponent
  end

  def match_host?(tournament_round)
    match = host_tournament_matches.find_by(tournament_round: tournament_round)

    return true if match

    false
  end
end

class Club < ApplicationRecord
  belongs_to :tournament

  has_many :players
  has_many :host_tournament_matches, foreign_key: 'host_club_id', class_name: 'TournamentMatch', dependent: :destroy
  has_many :guest_tournament_matches, foreign_key: 'guest_club_id', class_name: 'TournamentMatch', dependent: :destroy

  enum status: %i[active archived]

  validates :name, uniqueness: true
  validates :code, uniqueness: true

  scope :order_by_players_count, -> { includes(:players).left_joins(:players).group(:id).order(Arel.sql('COUNT(players.id) DESC')) }

  def logo_path
    "clubs/#{path_name}.png"
  end

  def path_name
    name.downcase.tr(' ', '_')
  end

  def opponent_by_round(tournament_round)
    match = host_tournament_matches.where(tournament_round: tournament_round).first

    if match
      opponent = match.guest_club
    else
      match = guest_tournament_matches.where(tournament_round: tournament_round).first
      opponent = match.host_club
    end

    opponent
  end
end

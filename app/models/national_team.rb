class NationalTeam < ApplicationRecord
  belongs_to :tournament

  has_many :players, dependent: :nullify
  has_many :host_national_matches, foreign_key: 'host_team_id', class_name: 'NationalMatch',
                                   dependent: :destroy, inverse_of: :host_team
  has_many :guest_national_matches, foreign_key: 'guest_team_id', class_name: 'NationalMatch',
                                    dependent: :destroy, inverse_of: :guest_team

  enum status: { active: 0, archived: 1 }

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true

  def opponent_by_round(tournament_round)
    match = host_national_matches.find_by(tournament_round: tournament_round)

    if match
      opponent = match.guest_team
    else
      match = guest_national_matches.find_by(tournament_round: tournament_round)
      opponent = match.host_team
    end

    opponent
  end

  def matches
    @matches ||= NationalMatch.by_team(id).by_t_round(tournament.tournament_rounds)
  end
end

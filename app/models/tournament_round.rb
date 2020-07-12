class TournamentRound < ApplicationRecord
  belongs_to :tournament
  belongs_to :season

  has_many :tournament_matches, dependent: :destroy
end

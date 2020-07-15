class RoundPlayer < ApplicationRecord
  belongs_to :tournament_round
  belongs_to :player

  has_many :match_players

  # TODO: move all scores and bonuses from MatchPlayer
  # except: cleansheet(as it depends on lineup position), real_position, position_malus, subs_status
end

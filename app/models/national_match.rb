class NationalMatch < ApplicationRecord
  belongs_to :tournament_round
  belongs_to :host_team, class_name: 'NationalTeam'
  belongs_to :guest_team, class_name: 'NationalTeam'
end

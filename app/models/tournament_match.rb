class TournamentMatch < ApplicationRecord
  belongs_to :tournament_round
  belongs_to :host_club, class_name: 'Club', foreign_key: 'host_club_id'
  belongs_to :guest_club, class_name: 'Club', foreign_key: 'guest_club_id'
end

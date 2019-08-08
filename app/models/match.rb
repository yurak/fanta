class Match < ApplicationRecord
  belongs_to :tour
  belongs_to :host, class_name: 'Team', foreign_key: 'host_id'
  belongs_to :guest, class_name: 'Team', foreign_key: 'guest_id'

  def host_lineup
    Lineup.where(tour: tour, team: host).last
  end

  def guest_lineup
    Lineup.where(tour: tour, team: guest).last
  end
end

class Match < ApplicationRecord
  belongs_to :tour
  belongs_to :host, class_name: 'Team', foreign_key: 'host_id'
  belongs_to :guest, class_name: 'Team', foreign_key: 'guest_id'

  scope :by_team_and_tour, ->(team_id, tour_id) { where(tour_id: tour_id).where('host_id = ? OR guest_id = ?', team_id, team_id) }

  def host_lineup
    @host_lineup ||= Lineup.where(tour: tour, team: host).last
  end

  def guest_lineup
    @guest_lineup ||= Lineup.where(tour: tour, team: guest).last
  end

  def host_score
    host_lineup&.total_score
  end

  def guest_score
    guest_lineup&.total_score
  end

  def host_goals
    @host_goals ||= host_lineup ? host_lineup.goals : 0
  end

  def guest_goals
    @guest_goals ||= guest_lineup ? guest_lineup.goals : 0
  end

  def scored_goals(team)
    host == team ? host_goals : guest_goals
  end

  def missed_goals(team)
    host == team ? guest_goals : host_goals
  end

  def host_win?
    host_goals > guest_goals
  end

  def guest_win?
    guest_goals > host_goals
  end

  def draw?
    host_goals == guest_goals
  end
end

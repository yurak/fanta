class TournamentMatch < ApplicationRecord
  belongs_to :tournament_round
  belongs_to :host_club, class_name: 'Club'
  belongs_to :guest_club, class_name: 'Club'

  serialize :missed_players_data, coder: JSON

  scope :by_club, ->(club_id) { where('host_club_id = ? OR guest_club_id = ?', club_id, club_id) }
  scope :by_club_and_t_round, ->(club_id, t_round_id) { by_club(club_id).where(tournament_round_id: t_round_id) }

  def utc_datetime
    return nil if date.blank? || time.blank?

    DateTime.parse("#{date} #{time} UTC")
  rescue ArgumentError
    nil
  end
end

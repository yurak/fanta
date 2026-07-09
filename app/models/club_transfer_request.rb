class ClubTransferRequest < ApplicationRecord
  OUTSIDE_CLUB_NAME = 'Outside'.freeze

  belongs_to :player
  belongs_to :old_club, class_name: 'Club', optional: true
  belongs_to :new_club, class_name: 'Club', optional: true

  enum :status, { pending: 0, confirmed: 1, rejected: 2 }

  validates :new_club_name, presence: true
  validates :start_date, presence: true

  # Number of Mantra teams that currently own this player.
  def teams_count
    player.teams.size
  end

  # Whether applying this transfer takes the player out of his current tournament.
  def leaves_championship?
    !same_tournament_move?
  end

  # :red    — leaves the championship and is owned by teams
  # :yellow — leaves the championship and is owned by no team
  # :blue   — stays in the championship and is owned by teams
  # :green  — stays in the championship and is owned by no team
  def teams_status
    if leaves_championship?
      teams_count.positive? ? :red : :yellow
    else
      teams_count.positive? ? :blue : :green
    end
  end

  private

  def destination_club
    new_club_id && new_club ? new_club : Club.find_by(name: OUTSIDE_CLUB_NAME)
  end

  def same_tournament_move?
    player.club&.same_active_tournament_as?(destination_club) || false
  end
end

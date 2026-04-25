class WeeklyTeamPlayer < ApplicationRecord
  belongs_to :weekly_team
  belongs_to :slot
  belongs_to :round_player

  validates :slot_id, uniqueness: { scope: :weekly_team_id }
end

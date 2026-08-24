class WeeklyTeamPlayer < ApplicationRecord
  belongs_to :weekly_team
  belongs_to :slot
  belongs_to :round_player, optional: true
  belongs_to :player, optional: true

  validates :slot_id, uniqueness: { scope: :weekly_team_id }
  validate :player_or_round_player

  scope :with_admin_includes, -> { includes(:player, round_player: :player) }

  def resolved_player
    player || round_player&.player
  end

  def resolved_club
    round_player&.club || resolved_player&.club
  end

  private

  def player_or_round_player
    return if player_id.present? || round_player_id.present?

    errors.add(:base, 'either player or round_player must be present')
  end
end

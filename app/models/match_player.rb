class MatchPlayer < ApplicationRecord
  belongs_to :player
  belongs_to :lineup

  delegate :position_names, to: :player

  def malus
    return 0 if own_position?
  end

  def own_position?
    position_names.include?(real_position)
  end
end

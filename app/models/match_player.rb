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

  def total_score
    return 0 unless score
    total = score
    total += 1 if cleansheet
    total -= 0.5 if yellow_card
    total -= 1 if red_card

    total += goals*3 if goals
    total += assits if assits
    total -= missed_goals*2 if missed_goals

    total -= malus if malus
    total += bonus if bonus

    return total
  end
end

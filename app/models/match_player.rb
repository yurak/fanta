class MatchPlayer < ApplicationRecord
  belongs_to :player
  belongs_to :lineup

  delegate :position_names, to: :player

  scope :main, ->{ where.not(real_position: nil) }
  scope :subs, ->{ where(real_position: nil) }

  def malus
    return 0 if own_position?
  end

  def own_position?
    position_names.include?(real_position)
  end

  def total_score
    return 0 unless score
    total = score

    # bonuses
    total += goals*3 if goals
    total += caught_penalty*3 if caught_penalty
    total += scored_penalty*2 if scored_penalty
    total += assists if assists
    total += 1 if cleansheet

    # maluses
    total -= missed_goals*2 if missed_goals
    total -= missed_penalty if missed_penalty
    total -= failed_penalty*3 if failed_penalty
    total -= own_goals*2 if own_goals
    total -= 0.5 if yellow_card
    total -= 1 if red_card
    total -= position_malus if position_malus
    # total += bonus if bonus

    return total
  end
end

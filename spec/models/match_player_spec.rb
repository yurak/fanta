require 'rails_helper'

describe MatchPlayer, type: :model do
  describe '#total_score' do
    subject { match_player.total_score }
    let(:match_player) { create :match_player }

    context 'initial_score' do
      it { is_expected.to eq 0 }
    end

    context 'scored goals' do
      let(:match_player) { create :match_player, goals: 3 }
      it { is_expected.to eq 9 }
    end

    context 'scored goals and penalties' do
      let(:match_player) { create :match_player,goals: 3, caught_penalty: 1, scored_penalty: 2 }
      it { is_expected.to eq 16 }
    end

    context 'scored goals and penalties and cleansheets' do
      let(:match_player) { create :match_player, goals: 3, caught_penalty: 1, scored_penalty: 2, cleansheet: 3 }
      it { is_expected.to eq 17 }
    end
  end
end


  # total = score

  #   # bonuses
  #   total += goals * 3 if goals
  #   total += caught_penalty * 3 if caught_penalty
  #   total += scored_penalty * 2 if scored_penalty
  #   total += assists if assists
  #   total += 1 if cleansheet

  #   # maluses
  #   total -= missed_goals * 2 if missed_goals
  #   total -= missed_penalty if missed_penalty
  #   total -= failed_penalty * 3 if failed_penalty
  #   total -= own_goals * 2 if own_goals
  #   total -= 0.5 if yellow_card
  #   total -= 1 if red_card
  #   total -= position_malus if position_malus
  #   # total += bonus if bonus

  #   total

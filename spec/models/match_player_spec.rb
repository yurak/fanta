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
      let(:match_player) { create :match_player, goals: 3, caught_penalty: 1, scored_penalty: 2 }
      it { is_expected.to eq 16 }
    end

    context 'scored goals and penalties and cleansheets' do
      let(:match_player) { create :match_player, goals: 3, caught_penalty: 1, scored_penalty: 2, cleansheet: 3 }
      it { is_expected.to eq 17 }
    end

    context 'scored goals and penalties and cleansheets and cards' do
      let(:match_player) { create :match_player, goals: 3, caught_penalty: 1, scored_penalty: 2, cleansheet: 3 }
      it { is_expected.to eq 17 }
    end

    context 'scored goals and penalties and cleansheets and cards' do
      let(:match_player) { create :match_player, goals: 3, caught_penalty: 1, cleansheet: 3, yellow_card: 1, red_card: 1 }
      it { is_expected.to eq 11.5 }
    end
  end
end

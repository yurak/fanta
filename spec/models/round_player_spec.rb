require 'rails_helper'

describe RoundPlayer, type: :model do
  describe '#result_score' do
    subject { round_player.result_score }
    let(:round_player) { create :round_player }

    context 'initial_score' do
      it { is_expected.to eq 0 }
    end

    context 'scored goals' do
      let(:round_player) { create :round_player, goals: 3 }
      it { is_expected.to eq 9 }
    end

    context 'scored goals and penalties' do
      let(:round_player) { create :round_player, goals: 3, caught_penalty: 1, scored_penalty: 2 }
      it { is_expected.to eq 16 }
    end

    context 'scored goals and penalties and cards' do
      let(:round_player) { create :round_player, goals: 3, caught_penalty: 1, yellow_card: 1, red_card: 1 }
      it { is_expected.to eq 10.5 }
    end
  end
end

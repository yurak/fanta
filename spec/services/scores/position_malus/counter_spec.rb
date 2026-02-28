RSpec.describe Scores::PositionMalus::Counter do
  describe '#call' do
    subject { described_class.call(real_position, player_positions) }

    context 'when player plays in native single position' do
      let(:real_position) { 'Dc' }
      let(:player_positions) { ['Dc'] }

      it { is_expected.to eq(0) }
    end

    context 'when real_position is compound and one slot matches native position' do
      let(:real_position) { 'Ds/Dd' }
      let(:player_positions) { ['Dd'] }

      it { is_expected.to eq(0) }
    end

    context 'when player has small malus (S_MALUS)' do
      let(:real_position) { 'Dd' }
      let(:player_positions) { ['Dc'] }

      it { is_expected.to eq(Position::S_MALUS) }
    end

    context 'when player has medium malus (M_MALUS)' do
      let(:real_position) { 'Dd' }
      let(:player_positions) { ['E'] }

      it { is_expected.to eq(Position::M_MALUS) }
    end

    context 'when player has no matching malus entry' do
      let(:real_position) { 'Dd' }
      let(:player_positions) { ['Por'] }

      it { is_expected.to eq(Position::L_MALUS) }
    end

    context 'when player has multiple positions and one reduces malus' do
      let(:real_position) { 'Dd' }
      let(:player_positions) { %w[E Dc] }

      it { is_expected.to eq(Position::S_MALUS) }
    end

    context 'when real_position is compound and minimum malus is taken across slots' do
      let(:real_position) { 'Dc/M' }
      let(:player_positions) { ['E'] }

      it { is_expected.to eq(Position::S_MALUS) }
    end
  end
end

RSpec.describe Slot, type: :model do
  subject(:slot) { create(:slot) }

  describe 'Associations' do
    it { is_expected.to belong_to(:team_module) }
  end

  describe '#positions' do
    context 'without position' do
      it 'returns empty array' do
        expect(slot.positions).to eq([])
      end
    end

    context 'with single position' do
      let(:slot) { create(:slot, position: 'M') }

      it 'returns array with position' do
        expect(slot.positions).to eq(%w[M])
      end
    end

    context 'with multiple positions' do
      let(:slot) { create(:slot, position: 'M/C') }

      it 'returns array with positions' do
        expect(slot.positions).to eq(%w[M C])
      end
    end
  end

  describe '#positions_with_malus' do
    context 'without position' do
      it 'returns empty array' do
        expect(slot.positions_with_malus).to eq([])
      end
    end

    context 'with position' do
      let(:slot) { create(:slot, position: 'M') }

      it 'returns array with possible positions' do
        expect(slot.positions_with_malus).to eq(%w[M C Dc])
      end
    end

    context 'with multiple positions' do
      let(:slot) { create(:slot, position: 'E/W') }

      it 'returns array with possible positions' do
        expect(slot.positions_with_malus).to eq(%w[E Dd Ds W T A])
      end
    end
  end
end

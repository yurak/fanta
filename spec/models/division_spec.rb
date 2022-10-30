RSpec.describe Division do
  subject(:division) { create(:division) }

  describe 'Associations' do
    it { is_expected.to have_many(:leagues).dependent(:destroy) }
  end

  describe '#name' do
    context 'without level' do
      let(:division) { create(:division, level: nil) }

      it 'returns empty string' do
        expect(division.name).to eq('')
      end
    end

    context 'with level' do
      it 'returns empty string' do
        expect(division.name).to eq(division.level + division.number.to_s)
      end
    end
  end
end

RSpec.describe DefenceBonus do
  describe '.for_scores' do
    it 'returns 0 with no defenders' do
      expect(described_class.for_scores([])).to eq(0)
    end

    it 'returns 0 when the average is below the minimum' do
      expect(described_class.for_scores([6.0, 6.0])).to eq(0)
    end

    it 'returns the minimal bonus at the minimum threshold' do
      expect(described_class.for_scores([7.0, 7.0])).to eq(1)
    end

    it 'scales the bonus with the average' do
      expect(described_class.for_scores([7.5, 7.5])).to eq(3)
    end

    it 'caps the bonus at the maximum threshold' do
      expect(described_class.for_scores([8.0, 9.0])).to eq(5)
    end
  end

  describe '.for_average' do
    it 'honours custom min/max thresholds' do
      expect(described_class.for_average(6.5, min: 6, max: 7)).to eq(3)
    end

    it 'caps at the maximum bonus for a custom range' do
      expect(described_class.for_average(7.0, min: 6, max: 7)).to eq(5)
    end
  end
end

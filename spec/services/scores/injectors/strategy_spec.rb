RSpec.describe Scores::Injectors::Strategy do
  describe '#call' do
    subject { described_class.new(tour) }

    let(:tour) { create(:tour, :serie_a) }
    let(:klass) { subject.klass }

    it 'returns calcio' do
      expect(klass).to eq Scores::Injectors::Calcio
    end
  end
end

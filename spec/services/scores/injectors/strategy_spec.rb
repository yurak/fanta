RSpec.describe Scores::Injectors::Strategy do
  describe '#call' do
    subject { described_class.new(tour) }
    let(:tour) { create(:tour, :serie_a) }

    it 'returns calcio' do
      expect(subject.klass).to eq Scores::Injectors::Calcio
    end
  end
end

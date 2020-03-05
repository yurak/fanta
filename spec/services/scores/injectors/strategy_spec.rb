RSpec.describe Scores::Injectors::Strategy do
  describe "#call" do
    subject { described_class.new(user) }
    let(:user) { create(:user) }

    it 'returns calcio' do
      expect(subject.klass).to eq Scores::Injectors::Calcio
    end
  end
end

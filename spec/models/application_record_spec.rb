RSpec.describe ApplicationRecord do
  describe '.abstract_class' do
    it 'is abstract' do
      expect(described_class.abstract_class).to be(true)
    end
  end
end

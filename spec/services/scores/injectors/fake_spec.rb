RSpec.describe Scores::Injectors::Fake do
  subject(:injector) { described_class.new(tour: tour) }

  let(:tour) { create(:tour) }

  describe '#call' do
    it { expect { injector.call }.to raise_error(NotImplementedError) }
  end
end

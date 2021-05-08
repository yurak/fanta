RSpec.describe Slots::Updater do
  describe '#call' do
    subject(:updater) { described_class.new }

    context 'with existing slot' do
      let!(:slot) { create(:slot) }

      before do
        updater.call
      end

      it { expect(slot.reload.location).to eq('d1') }
    end
  end
end

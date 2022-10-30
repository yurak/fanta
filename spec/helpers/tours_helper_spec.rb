RSpec.describe ToursHelper do
  describe '#time_to_deadline(time_hash)' do
    let(:time_hash) { nil }

    context 'without time_hash' do
      it 'returns empty array' do
        expect(helper.time_to_deadline(time_hash)).to eq('')
      end
    end

    context 'with time_hash' do
      let(:time_hash) { { days: 3, minutes: 45 } }

      it 'returns empty array' do
        expect(helper.time_to_deadline(time_hash)).to eq('3d 45m left')
      end
    end
  end
end

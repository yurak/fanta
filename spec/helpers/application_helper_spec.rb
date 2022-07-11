RSpec.describe ApplicationHelper, type: :helper do
  describe '#position_number(index)' do
    context 'with prize index' do
      it 'returns medal emoji' do
        expect(helper.position_number(1)).to eq('🥇')
      end
    end

    context 'with lower index' do
      let(:index) { 5 }

      it 'returns index' do
        expect(helper.position_number(index)).to eq(index)
      end
    end
  end
end

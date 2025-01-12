RSpec.describe ApplicationHelper do
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

  describe '#position_manager_number(index)' do
    context 'with prize index' do
      it 'returns medal emoji' do
        expect(helper.position_manager_number(1)).to eq('🥇 #1')
      end
    end

    context 'with lower index' do
      let(:index) { 5 }

      it 'returns index' do
        expect(helper.position_manager_number(index)).to eq('#5')
      end
    end
  end

  describe '#ordinalize_number(number)' do
    context 'without number' do
      it 'returns -' do
        expect(helper.ordinalize_number(nil)).to eq('-')
      end
    end

    context 'with number and en locale' do
      it 'returns ordinalize number' do
        expect(helper.ordinalize_number(2)).to eq('2nd')
      end
    end

    context 'with number and ua locale' do
      before do
        I18n.with_locale(:ua)
      end

      it 'returns ordinalize number' do
        expect(helper.ordinalize_number(2)).to eq(2)
      end
    end
  end
end

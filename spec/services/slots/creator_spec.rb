RSpec.describe Slots::Creator do
  describe '#call' do
    subject(:creator) { described_class.new }

    let(:file_content) do
      {
        '5-3-2' => {
          1 => %w[Por],
          2 => %w[Dc],
          3 => %w[Dc],
          4 => %w[Dc],
          5 => %w[Ds],
          6 => %w[Dd],
          7 => %w[M C],
          8 => %w[C],
          9 => %w[C],
          10 => %w[A Pc],
          11 => %w[A Pc]
        }
      }
    end

    context 'without existed clubs' do
      let(:file_content) { {} }

      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
      end

      it { expect(creator.call).to be(false) }
    end

    context 'with modules in file' do
      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it 'creates team module' do
        expect(TeamModule.count).to eq(12)
      end

      it 'creates slots' do
        expect(TeamModule.last.slots.count).to eq(11)
      end
    end

    context 'when module with same name exist' do
      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
        creator.call
      end

      it { expect(TeamModule.count).to eq(12) }
    end
  end
end

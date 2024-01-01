RSpec.describe Positions::Creator do
  describe '#call' do
    subject(:creator) { described_class.new }

    let(:file_content) { { 'positions' => %w[Pos1 Pos2 Pos3] } }

    context 'with unique names' do
      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Position.count).to eq(14) }
      it { expect(Position.last.name).to eq('Pos3') }
    end

    context 'with duplicated names' do
      let(:file_content) { { 'positions' => %w[Pos1 Pos2 Pos2] } }

      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Position.count).to eq(13) }
      it { expect(Position.last.name).to eq('Pos2') }
    end
  end
end

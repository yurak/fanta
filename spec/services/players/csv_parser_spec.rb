RSpec.describe Players::CsvParser do
  describe '#call' do
    subject(:parser) { described_class.new(file_name) }

    let(:file_name) { 'file_name' }

    context 'without existing file' do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it { expect(parser.call).to eq(false) }
    end

    context 'with existing file' do
      let(:file_name) { 'test' }

      it 'call' do
        manager = instance_double(Players::Manager)

        allow(manager).to receive(:call).exactly(3).times

        parser.call
      end
    end
  end
end

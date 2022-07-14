RSpec.describe Players::CsvParser do
  describe '#call' do
    subject(:parser) { described_class.new(file_url, file_name) }

    let(:file_name) { nil }
    let(:file_url) { nil }

    context 'without file_name and file_url' do
      it { expect(parser.call).to be(false) }
    end

    context 'with file_name but without existing file' do
      let(:file_name) { 'file_name' }

      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it { expect(parser.call).to be(false) }
    end

    context 'with file_name and existing file' do
      let(:file_name) { 'test' }

      it 'call' do
        manager = instance_double(Players::Manager)

        allow(manager).to receive(:call).exactly(3).times

        parser.call
      end
    end

    context 'with file_url' do
      let(:file_url) { 'https://mantrafootball.s3.eu-west-1.amazonaws.com/players_lists/test.csv' }

      it 'call' do
        VCR.use_cassette 'csv_parser_aws' do
          manager = instance_double(Players::Manager)

          allow(manager).to receive(:call).exactly(3).times

          parser.call
        end
      end
    end
  end
end

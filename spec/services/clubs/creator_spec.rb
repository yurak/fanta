RSpec.describe Clubs::Creator do
  describe '#call' do
    subject(:creator) { described_class.new }

    let(:file_content) do
      {
        serie_a: {
          ATA: 'Atalanta',
          MIL: 'Milan',
          SAS: 'Sassuolo',
          VER: 'Verona'
        }
      }
    end

    context 'without existed clubs' do
      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.all.count).to eq(4) }
    end

    context 'with existed clubs with same name and code' do
      before do
        create(:club, name: 'Milan', code: 'MIL', tournament: Tournament.find_by(code: 'serie_a'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.all.count).to eq(4) }
    end

    context 'with existed clubs with same name' do
      before do
        create(:club, name: 'Sassuolo', code: 'OLO', tournament: Tournament.find_by(code: 'serie_a'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.all.count).to eq(4) }
    end

    context 'with existed clubs with same code' do
      before do
        create(:club, name: 'Atlas', code: 'ATA', tournament: Tournament.find_by(code: 'serie_a'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.all.count).to eq(4) }
    end

    context 'with existed clubs with other name and code' do
      before do
        create(:club, name: 'Inter', code: 'INT', tournament: Tournament.find_by(code: 'serie_a'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.all.count).to eq(5) }
    end

    context 'with multiple tournaments' do
      let(:file_content) do
        {
          serie_a: {
            ATA: 'Atalanta',
            MIL: 'Milan',
            SAS: 'Sassuolo',
            VER: 'Verona'
          },
          epl: {
            LIV: 'Liverpool',
            EVE: 'Everton'
          }
        }
      end

      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.all.count).to eq(6) }
    end

    context 'with invalid tournament code' do
      let(:file_content) do
        {
          league_two: {
            BOL: 'Bolton',
            OLD: 'Oldham'
          }
        }
      end

      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.all.count).to eq(0) }
    end

    context 'with multiple tournaments with one invalid tournament code' do
      let(:file_content) do
        {
          epl: {
            LIV: 'Liverpool',
            EVE: 'Everton'
          },
          league_two: {
            BOL: 'Bolton',
            OLD: 'Oldham'
          }
        }
      end

      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.all.count).to eq(2) }
    end
  end
end

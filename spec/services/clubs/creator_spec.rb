RSpec.describe Clubs::Creator do
  describe '#call' do
    subject(:creator) { described_class.new }

    let(:file_content) do
      {
        italy: {
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

      it { expect(Club.count).to eq(4) }
    end

    context 'with existed clubs with same name and code' do
      before do
        create(:club, name: 'Milan', code: 'MIL', tournament: Tournament.find_by(code: 'italy'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.count).to eq(4) }
    end

    context 'with existed clubs with same name' do
      before do
        create(:club, name: 'Sassuolo', code: 'OLO', tournament: Tournament.find_by(code: 'italy'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.count).to eq(4) }
    end

    context 'with existed clubs with same code' do
      before do
        create(:club, name: 'Atlas', code: 'ATA', tournament: Tournament.find_by(code: 'italy'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.count).to eq(4) }
    end

    context 'with existed clubs with other name and code' do
      before do
        create(:club, name: 'Inter', code: 'INT', tournament: Tournament.find_by(code: 'italy'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.count).to eq(5) }
    end

    context 'with multiple tournaments' do
      let(:file_content) do
        {
          italy: {
            ATA: 'Atalanta',
            MIL: 'Milan',
            SAS: 'Sassuolo',
            VER: 'Verona'
          },
          england: {
            LIV: 'Liverpool',
            EVE: 'Everton'
          }
        }
      end

      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.count).to eq(6) }
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

      it { expect(Club.count).to eq(0) }
    end

    context 'with multiple tournaments with one invalid tournament code' do
      let(:file_content) do
        {
          england: {
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

      it { expect(Club.count).to eq(2) }
    end

    context 'when eurocup tournament with existed clubs' do
      let(:file_content) do
        {
          europe: {
            ATA: 'Atalanta',
            MIL: 'Milan',
            LIV: 'Liverpool',
            AJA: 'Ajax'
          }
        }
      end

      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.count).to eq(4) }
    end

    context 'when eurocup tournament with existed clubs with same name' do
      let(:file_content) do
        {
          europe: {
            ATA: 'Atalanta',
            MIL: 'Milan',
            LIV: 'Liverpool',
            AJA: 'Ajax'
          }
        }
      end
      let!(:club) { create(:club, name: 'Milan', code: 'MLN') }

      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(Club.count).to eq(4) }

      it 'adds eurocup tournament to club' do
        expect(club.reload.ec_tournament.code).to eq('europe')
      end
    end
  end
end

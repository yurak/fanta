RSpec.describe NationalTeams::Creator do
  describe '#call' do
    subject(:creator) { described_class.new }

    let(:file_content) do
      {
        euro: {
          ua: 'Ukraine',
          it: 'Italy',
          de: 'Germany',
          fr: 'France'
        }
      }
    end

    context 'without existed national teams' do
      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(NationalTeam.all.count).to eq(4) }
    end

    context 'with existed national team with same code' do
      before do
        create(:national_team, name: 'Belgium', code: 'ua', tournament: Tournament.find_by(code: 'euro'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(NationalTeam.all.count).to eq(4) }
    end

    context 'with existed national team with same name' do
      before do
        create(:national_team, name: 'Ukraine', code: 'be', tournament: Tournament.find_by(code: 'euro'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(NationalTeam.all.count).to eq(4) }
    end

    context 'with existed national team with other code' do
      before do
        create(:national_team, name: 'Belgium', code: 'be', tournament: Tournament.find_by(code: 'euro'))
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(NationalTeam.all.count).to eq(5) }
    end

    context 'with invalid tournament code' do
      let(:file_content) do
        {
          super_league: {
            ua: 'Ukraine',
            fr: 'France'
          }
        }
      end

      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(NationalTeam.all.count).to eq(0) }
    end

    context 'with multiple tournaments with one invalid tournament code' do
      let(:file_content) do
        {
          euro: {
            ua: 'Ukraine',
            it: 'Italy',
            de: 'Germany',
            fr: 'France',
            hr: 'Croatia',
            be: 'Belgium'
          },
          super_league: {
            br: 'Brazil',
            us: 'United States'
          }
        }
      end

      before do
        allow(YAML).to receive(:load_file).and_return(file_content)
        creator.call
      end

      it { expect(NationalTeam.all.count).to eq(6) }
    end
  end
end

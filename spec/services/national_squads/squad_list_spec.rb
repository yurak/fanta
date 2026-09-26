RSpec.describe NationalSquads::SquadList do
  describe '.path' do
    context 'with a name given' do
      it 'points at that file in the squads directory' do
        expect(described_class.path('euro_2028.csv')).to eq(described_class::DIR.join('euro_2028.csv').to_s)
      end
    end

    context 'without a name' do
      before do
        allow(Dir).to receive(:[]).and_return(['/squads/old.csv', '/squads/new.csv',
                                               '/squads/nl_missing_players.csv'])
        allow(File).to receive(:mtime).with('/squads/old.csv').and_return(Time.zone.parse('2026-01-01'))
        allow(File).to receive(:mtime).with('/squads/new.csv').and_return(Time.zone.parse('2026-09-01'))
      end

      it 'takes the newest list' do
        expect(described_class.path).to eq('/squads/new.csv')
      end

      # The missing-players file sits in the same directory and is not a squad list.
      it 'never takes the missing-players file' do
        allow(File).to receive(:mtime).with('/squads/nl_missing_players.csv').and_return(Time.zone.parse('2027-01-01'))

        expect(described_class.path).not_to include('missing')
      end
    end
  end
end

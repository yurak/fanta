require 'rails_helper'

RSpec.describe ClubTransfers::HistoryImporter do
  let(:player) { create(:player, tm_id: 400_489) }
  let(:mantra_club) { create(:club, tm_url: 'https://www.transfermarkt.com/leipzig/startseite/verein/23826') }

  let(:history) do
    [
      {
        tm_transfer_id: 5_909_893, old_club_name: 'Napoli', old_tm_club_id: '6195',
        new_club_name: 'Leipzig', new_tm_club_id: '23826', start_date: Date.new(2026, 6, 30),
        season: '25/26', fee: 'End of loan', market_value: '€13.00m', loan: false, upcoming: false
      },
      {
        tm_transfer_id: 5_111_111, old_club_name: 'Leipzig', old_tm_club_id: '23826',
        new_club_name: 'Torino', new_tm_club_id: '416', start_date: Date.new(2025, 1, 30),
        season: '24/25', fee: 'loan transfer', market_value: '€18.00m', loan: true, upcoming: false
      }
    ]
  end

  before do
    allow(Players::Transfermarkt::TransferHistoryParser).to receive(:call).with(player.tm_id).and_return(history)
  end

  describe '#call' do
    it 'creates a club_transfer per TM transfer' do
      expect { described_class.call(player) }.to change(player.club_transfers, :count).by(2)
    end

    it 'returns the number of imported transfers' do
      expect(described_class.call(player)).to eq(2)
    end

    it 'stores the TM fields' do
      described_class.call(player)
      record = player.club_transfers.find_by(tm_transfer_id: 5_909_893)
      expect(record).to have_attributes(new_club_name: 'Leipzig', new_tm_club_id: '23826',
                                        season: '25/26', fee: 'End of loan', market_value: '€13.00m')
    end

    it 'resolves our Club by TM club id' do
      mantra_club
      described_class.call(player)
      expect(player.club_transfers.find_by(tm_transfer_id: 5_909_893).new_club_id).to eq(mantra_club.id)
    end

    it 'leaves club_id nil for non-Mantra clubs' do
      described_class.call(player)
      expect(player.club_transfers.find_by(tm_transfer_id: 5_111_111).new_club_id).to be_nil
    end

    it 'is idempotent when run twice' do
      described_class.call(player)
      expect { described_class.call(player) }.not_to change(ClubTransfer, :count)
    end

    context 'when the player has no tm_id' do
      let(:player) { create(:player, tm_id: nil) }

      it { expect(described_class.call(player)).to eq(0) }
    end
  end
end

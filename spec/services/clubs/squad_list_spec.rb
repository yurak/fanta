require 'rails_helper'

RSpec.describe Clubs::SquadList do
  let(:club) { create(:club, tm_url: 'https://www.transfermarkt.com/x/startseite/verein/23826') }

  before do
    allow(Players::Transfermarkt::ClubSquadParser).to receive(:call).and_return(%w[111 222])
    allow(Players::Transfermarkt::ApiParser).to receive(:call)
      .and_return({ first_name: 'New', name: 'Guy', tm_pos1: 'CB', tm_price: 5_000_000,
                    nationality: 'br', birth_date: '25/11/2005' })
    allow(Players::Transfermarkt::TransferHistoryParser).to receive(:call).and_return([])
  end

  it 'lists existing players before new ones' do
    create(:player, tm_id: 222, name: 'Existing')

    expect(described_class.call(club)[:squad].pluck(:tm_id)).to eq(%w[222 111])
  end

  it 'attaches the player record to existing entries' do
    existing = create(:player, tm_id: 111)

    entry = described_class.call(club)[:squad].find { |e| e[:tm_id] == '111' }
    expect(entry[:player]).to eq(existing)
  end

  it 'builds new entries from fetched TM data' do
    entry = described_class.call(club)[:squad].find { |e| e[:player].nil? }

    expect(entry).to include(name: 'New Guy', position: 'CB', price: 5_000_000, nationality: 'br',
                             birth_date: '25/11/2005')
  end

  describe 'club mismatch' do
    it 'is not flagged when the player already belongs to the club' do
      create(:player, tm_id: 111, club: club)

      entry = described_class.call(club)[:squad].find { |e| e[:tm_id] == '111' }
      expect(entry).to include(wrong_club: false, current_club: club.name)
    end

    it 'is flagged when the player belongs to another club in our base' do
      other = create(:club, name: 'Free agent')
      create(:player, tm_id: 111, club: other)

      entry = described_class.call(club)[:squad].find { |e| e[:tm_id] == '111' }
      expect(entry).to include(wrong_club: true, current_club: 'Free agent')
    end

    it 'is not flagged for players missing from our base' do
      entry = described_class.call(club)[:squad].find { |e| e[:tm_id] == '222' }
      expect(entry[:wrong_club]).to be_nil
    end
  end

  describe 'missing players' do
    it 'includes club players whose tm_id is not in the TM squad' do
      gone = create(:player, tm_id: 999, club: club)

      expect(described_class.call(club)[:missing].pluck(:player)).to include(gone)
    end

    it 'includes club players with no tm_id' do
      no_tm = create(:player, tm_id: nil, club: club)

      expect(described_class.call(club)[:missing].pluck(:player)).to include(no_tm)
    end

    it 'excludes club players still present in the TM squad' do
      still_here = create(:player, tm_id: 111, club: club)

      expect(described_class.call(club)[:missing].pluck(:player)).not_to include(still_here)
    end

    it 'reports the current TM club from the latest transfer' do
      transfer = { new_club_name: 'New FC', start_date: Time.zone.today - 1, upcoming: false, tm_transfer_id: 5 }
      player = create(:player, tm_id: 999, club: club)
      allow(Players::Transfermarkt::TransferHistoryParser).to receive(:call).with(player.tm_id).and_return([transfer])
      entry = described_class.call(club)[:missing].find { |e| e[:player] == player }

      expect(entry[:current_tm_club]).to eq('New FC')
    end
  end
end

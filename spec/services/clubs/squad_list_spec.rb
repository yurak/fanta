require 'rails_helper'

RSpec.describe Clubs::SquadList do
  let(:club) { create(:club, tm_url: 'https://www.transfermarkt.com/x/startseite/verein/23826') }

  before do
    allow(Players::Transfermarkt::ClubSquadParser).to receive(:call).and_return(%w[111 222])
    allow(Players::Transfermarkt::ApiParser).to receive(:call)
      .and_return({ first_name: 'New', name: 'Guy', tm_pos1: 'CB', tm_price: 5_000_000, nationality: 'br' })
  end

  it 'lists existing players before new ones' do
    create(:player, tm_id: 222, name: 'Existing')

    expect(described_class.call(club).pluck(:tm_id)).to eq(%w[222 111])
  end

  it 'attaches the player record to existing entries' do
    existing = create(:player, tm_id: 111)

    entry = described_class.call(club).find { |e| e[:tm_id] == '111' }
    expect(entry[:player]).to eq(existing)
  end

  it 'builds new entries from fetched TM data' do
    entry = described_class.call(club).find { |e| e[:player].nil? }

    expect(entry).to include(name: 'New Guy', position: 'CB', price: 5_000_000, nationality: 'br')
  end
end

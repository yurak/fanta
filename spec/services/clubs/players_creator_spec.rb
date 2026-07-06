require 'rails_helper'

RSpec.describe Clubs::PlayersCreator do
  before do
    allow(Players::Transfermarkt::ApiParser).to receive(:call).and_return({ name: 'Ronaldo', club_name: 'X' })
    allow(Players::Manager).to receive(:call).and_return(true)
  end

  it 'returns the number of created players' do
    expect(described_class.call(%w[111 222])).to eq(2)
  end

  it 'creates a player for each new id' do
    described_class.call(%w[111 222])

    expect(Players::Manager).to have_received(:call).twice
  end

  it 'skips blank ids' do
    described_class.call(['111', '', nil])

    expect(Players::Manager).to have_received(:call).once
  end

  it 'skips players that already exist' do
    create(:player, tm_id: 111)

    expect(described_class.call(%w[111])).to eq(0)
  end
end

# spec/services/players/transfermarkt/position_parser_spec.rb
require 'rails_helper'

RSpec.describe Players::Transfermarkt::PositionParser do
  describe '#call' do
    subject(:parser) { described_class.new(player, year) }

    let(:year)   { 2023 }
    let(:player) { create(:player, tm_id: '406040') }

    context 'when player has no tm_id' do
      let(:player) { create(:player, tm_id: nil) }

      it 'returns empty hash' do
        expect(parser.call).to eq({})
      end
    end

    context 'when positions page exists' do
      let(:positions_html) do
        Rails.root.join('spec/fixtures/tm/positions_406040_2023.html').read
      end

      before do
        allow_any_instance_of(Players::Transfermarkt::BrowserClient).to receive(:fetch_html).and_return(positions_html)
      end

      it 'returns a hash' do
        result = parser.call
        expect(result).to be_a(Hash)
      end

      it 'returns non-empty stats' do
        result = parser.call
        expect(result.values.sum).to be > 0
      end

      it 'parses FW matches count' do
        result = parser.call
        expect(result['FW']).to eq(21)
      end

      it 'parses ST matches count' do
        result = parser.call
        expect(result['ST']).to eq(16)
      end

      it 'parses W matches count' do
        result = parser.call
        expect(result['W']).to eq(6)
      end

      it 'parses AM matches count' do
        result = parser.call
        expect(result['AM']).to eq(1)
      end
    end
  end
end

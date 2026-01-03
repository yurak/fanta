require 'rails_helper'

RSpec.describe Players::Transfermarkt::PositionMapper do
  describe '#call' do
    subject(:result) { described_class.new(player, year).call }

    let(:year)   { 2023 }
    let(:player) { create(:player, tm_id: nil) }

    before do
      allow(Kernel).to receive(:sleep)
    end

    context 'without player' do
      let(:player) { nil }

      it 'returns empty array' do
        expect(result).to eq([])
      end
    end

    context 'when player without tm_id' do
      it 'returns empty array' do
        expect(result).to eq([])
      end
    end

    context 'with tm_id and without matches' do
      let(:player) { create(:player, tm_id: '14555') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year).and_return({})
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'returns empty array' do
        expect(result).to eq([])
      end
    end

    context 'with matches on SS position' do
      let(:player) { create(:player, tm_id: '406040') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year).and_return({ 'ST' => 20 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({ 'FW' => 15 })
      end

      it 'returns position array' do
        expect(result).to contain_exactly('FW')
      end
    end

    context 'with RM played also on defence position' do
      let(:player) { create(:player, tm_id: '167491') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year)
                                                                       .and_return({ 'WB' => 20, 'RB' => 12 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'returns position array' do
        expect(result).to contain_exactly('WB', 'RB')
      end
    end

    context 'with lower second position' do
      let(:player) { create(:player, tm_id: '88755') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year)
                                                                       .and_return({ 'AM' => 20, 'CM' => 10 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'returns position array' do
        expect(result).to contain_exactly('AM')
      end
    end

    context 'with ST played on FW position in previous season' do
      let(:player) { create(:player, tm_id: '91845') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year).and_return({ 'ST' => 20 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({ 'FW' => 15 })
      end

      it 'returns position array' do
        expect(result).to contain_exactly('FW')
      end
    end

    context 'with AM or W played few matches on FW or ST position' do
      let(:player) { create(:player, tm_id: '144028') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year)
                                                                       .and_return({ 'W' => 20, 'FW' => 4 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'returns position array' do
        expect(result).to contain_exactly('W', 'FW')
      end
    end

    context 'with AM or W played a lot matches on FW or ST position' do
      let(:player) { create(:player, tm_id: '392085') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year)
                                                                       .and_return({ 'W' => 25, 'FW' => 20 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'returns position array' do
        expect(result).to contain_exactly('FW')
      end
    end
  end
end

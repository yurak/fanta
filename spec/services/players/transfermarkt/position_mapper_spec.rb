require 'rails_helper'

RSpec.describe Players::Transfermarkt::PositionMapper do
  describe '#call' do
    subject(:result) { described_class.new(player, year).call }

    let(:year)   { 2023 }
    let(:player) { create(:player, tm_id: nil) }

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

    context 'with ST and no previous season data' do
      let(:player) { create(:player, tm_id: '11001') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year).and_return({ 'ST' => 20 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'returns ST' do
        expect(result).to contain_exactly('ST')
      end
    end

    context 'with ST in both current and previous season' do
      let(:player) { create(:player, tm_id: '11002') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year).and_return({ 'ST' => 20 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({ 'ST' => 15 })
      end

      it 'returns ST' do
        expect(result).to contain_exactly('ST')
      end
    end

    context 'with FW as primary position' do
      let(:player) { create(:player, tm_id: '11003') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year).and_return({ 'FW' => 20 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'returns FW without processing second positions' do
        expect(result).to contain_exactly('FW')
      end
    end

    context 'with single RB position' do
      let(:player) { create(:player, tm_id: '11004') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year).and_return({ 'RB' => 20 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'adds WB' do
        expect(result).to contain_exactly('RB', 'WB')
      end
    end

    context 'with WB without defence in two seasons' do
      let(:player) { create(:player, tm_id: '11005') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year).and_return({ 'WB' => 20 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'returns only WB' do
        expect(result).to contain_exactly('WB')
      end
    end

    context 'with WB and CB played enough in two seasons' do
      let(:player) { create(:player, tm_id: '11006') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year).and_return({ 'WB' => 16 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({ 'CB' => 12 })
      end

      it 'adds CB' do
        expect(result).to contain_exactly('WB', 'CB')
      end
    end

    context 'with low current season matches, uses two seasons data' do
      let(:player) { create(:player, tm_id: '11007') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year).and_return({ 'W' => 8 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({ 'W' => 12 })
      end

      it 'merges both seasons' do
        expect(result).to contain_exactly('W')
      end
    end

    context 'when second position is on a lower line (other_line?)' do
      let(:player) { create(:player, tm_id: '12001') }

      shared_examples 'removes second position' do |first_pos, second_pos|
        context "with #{first_pos} + #{second_pos}" do
          before do
            allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year)
                                                                           .and_return({ first_pos => 20, second_pos => 10 })
            allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
          end

          it "returns only #{first_pos}" do
            expect(result).to contain_exactly(first_pos)
          end
        end
      end

      include_examples 'removes second position', 'W', 'WB'
      include_examples 'removes second position', 'W', 'CM'
      include_examples 'removes second position', 'W', 'DM'
      include_examples 'removes second position', 'DM', 'CB'
      include_examples 'removes second position', 'AM', 'WB'
      include_examples 'removes second position', 'AM', 'DM'
    end

    context 'with CM + DM (LOWER_POS_PAIRS match, same line)' do
      let(:player) { create(:player, tm_id: '12010') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year)
                                                                       .and_return({ 'CM' => 20, 'DM' => 10 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'removes DM' do
        expect(result).to contain_exactly('CM')
      end
    end

    context 'with equal match counts on two positions (skips removal)' do
      let(:player) { create(:player, tm_id: '12011') }

      before do
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year)
                                                                       .and_return({ 'W' => 15, 'WB' => 15 })
        allow(Players::Transfermarkt::PositionParser).to receive(:call).with(player, year - 1).and_return({})
      end

      it 'keeps both positions despite different lines' do
        expect(result).to contain_exactly('W', 'WB')
      end
    end
  end
end

RSpec.describe Players::Transfermarkt::PositionMapper do
  describe '#call' do
    subject(:parser) { described_class.new(player, year) }

    let(:player) { create(:player, tm_id: nil) }
    let(:year) { 2023 }

    context 'without player' do
      let(:player) { nil }

      it 'returns false' do
        expect(parser.call).to be(false)
      end
    end

    context 'when player without tm_id' do
      it 'returns false' do
        expect(parser.call).to be(false)
      end
    end

    context 'with tm_id and without matches' do
      let(:player) { create(:player, tm_id: '14555') }

      it 'returns position array' do
        VCR.use_cassette 'player_without_position' do
          expect(parser.call).to be(false)
        end
      end
    end

    context 'with matches on SS position' do
      let(:player) { create(:player, tm_id: '576024') }

      it 'returns position array' do
        VCR.use_cassette 'player_position_fw' do
          expect(parser.call).to contain_exactly('FW')
        end
      end
    end

    context 'with RM played also on defence position' do
      let(:player) { create(:player, tm_id: '167491') }

      it 'returns position array' do
        VCR.use_cassette 'player_position_wb_def' do
          expect(parser.call).to contain_exactly('WB', 'RB')
        end
      end
    end

    context 'with lower second position' do
      let(:player) { create(:player, tm_id: '88755') }

      it 'returns position array' do
        VCR.use_cassette 'player_position_am_cm' do
          expect(parser.call).to contain_exactly('AM')
        end
      end
    end

    context 'with ST played on FW position in previous season' do
      let(:player) { create(:player, tm_id: '91845') }

      it 'returns position array' do
        VCR.use_cassette 'player_position_st_fw' do
          expect(parser.call).to contain_exactly('FW')
        end
      end
    end

    context 'with AM or W played few matches on FW or ST position' do
      let(:player) { create(:player, tm_id: '144028') }

      it 'returns position array' do
        VCR.use_cassette 'player_position_am_fw' do
          expect(parser.call).to contain_exactly('W', 'FW')
        end
      end
    end

    context 'with AM or W played a lot matches on FW or ST position' do
      let(:player) { create(:player, tm_id: '392085') }

      it 'returns position array' do
        VCR.use_cassette 'player_position_w_am_fw' do
          expect(parser.call).to contain_exactly('FW')
        end
      end
    end
  end
end

RSpec.describe Players::Transfermarkt::Parser do
  describe '#call' do
    subject(:parser) { described_class.new(player) }

    let(:player) { create(:player, tm_id: '123456') }

    context 'without player' do
      let(:player) { nil }

      it { expect(parser.call).to be(false) }
    end

    context 'without player tm_id' do
      let(:player) { create(:player) }

      it { expect(parser.call).to be(false) }
    end

    context 'with player without number and price' do
      let(:player) { create(:player, tm_id: '29316') }

      it 'returns true' do
        VCR.use_cassette 'player_tm_parser_retired' do
          expect(parser.call).to be(true)
        end
      end
    end

    context 'with player tm_id without number and price' do
      let(:player) { create(:player, tm_id: '29316') }

      before do
        VCR.use_cassette 'player_tm_parser_retired' do
          parser.call
        end
      end

      it 'does not update price' do
        expect(player.reload.tm_price).to eq(0)
      end

      it 'does not update number' do
        expect(player.reload.number).to be_nil
      end
    end

    context 'with player full data' do
      let(:player) { create(:player, tm_id: '576024') }

      before do
        VCR.use_cassette 'player_tm_parser_full' do
          parser.call
        end
      end

      it 'updates price in millions' do
        expect(player.reload.tm_price).to eq(90_000_000)
      end

      it 'updates number' do
        expect(player.reload.number).to eq(19)
      end

      it 'updates height' do
        expect(player.reload.height).to eq(170)
      end

      it 'updates birth_date' do
        expect(player.reload.birth_date).to eq('Jan 31, 2000')
      end
    end

    context 'with chip player full data' do
      let(:player) { create(:player, tm_id: '986180') }

      before do
        VCR.use_cassette 'player_tm_parser_full_chip' do
          parser.call
        end
      end

      it 'updates price in thousands' do
        expect(player.reload.tm_price).to eq(150_000)
      end
    end
  end
end

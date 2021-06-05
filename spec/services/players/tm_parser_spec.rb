RSpec.describe Players::TmParser do
  describe '#call' do
    subject(:parser) { described_class.new(player) }

    let(:player) { create(:player, tm_url: 'valid') }

    # TODO: update test cases with vcr cassettes
    it 'is a pending example'

    # context 'without player' do
    #   let(:player) { nil }
    #
    #   it { expect(parser.call).to eq(false) }
    # end
    #
    # context 'without player tm_url' do
    #   let(:player) { create(:player) }
    #
    #   it { expect(parser.call).to eq(false) }
    # end
    #
    # context 'with player without number and price' do
    #   let(:player) { create(:player, tm_url: 'https://www.transfermarkt.com/cyril-thereau/profil/spieler/29316') }
    #
    #   before do
    #     parser.call
    #   end
    #
    #   it { expect(parser.call).to eq(true) }
    #   it { expect(player.reload.tm_price).to eq(0) }
    #   it { expect(player.reload.number).to eq(nil) }
    # end
    #
    # context 'with player full data' do
    #   let(:player) { create(:player, tm_url: 'https://www.transfermarkt.com/noah-katterbach/profil/spieler/469949') }
    #
    #   before do
    #     parser.call
    #   end
    #
    #   it { expect(parser.call).to eq(true) }
    #   it { expect(player.reload.tm_price).not_to eq(0) }
    #   it { expect(player.reload.number).not_to eq(nil) }
    #   it { expect(player.reload.height).not_to eq(nil) }
    #   it { expect(player.reload.birth_date).to eq('Apr 13, 2001') }
    # end
  end
end

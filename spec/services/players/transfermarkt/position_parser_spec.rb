RSpec.describe Players::Transfermarkt::PositionParser do
  describe '#call' do
    subject(:parser) { described_class.new(player, year) }

    let(:player) { create(:player, tm_id: '123456') }
    let(:year) { 2023 }

    # TODO: update test cases with vcr cassettes
    it 'is a pending example'
  end
end

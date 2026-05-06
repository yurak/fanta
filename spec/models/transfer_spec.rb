RSpec.describe Transfer do
  subject(:transfer) { create(:transfer) }

  describe 'Associations' do
    it { is_expected.to belong_to(:auction).optional }
    it { is_expected.to belong_to(:league) }
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:team) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:status).with_values(%i[incoming outgoing left]) }
  end

  describe '.by_league' do
    let(:league) { create(:league) }
    let!(:matched_transfer) { create(:transfer, league: league) }

    before do
      create(:transfer)
    end

    it 'returns transfers by league' do
      expect(described_class.by_league(league.id)).to eq([matched_transfer])
    end
  end

  describe '.by_player' do
    let(:player) { create(:player) }
    let!(:matched_transfer) { create(:transfer, player: player) }

    before do
      create(:transfer)
    end

    it 'returns transfers by player' do
      expect(described_class.by_player(player.id)).to eq([matched_transfer])
    end
  end

  describe '.by_auction' do
    let(:auction) { create(:auction) }
    let!(:matched_transfer) { create(:transfer, auction: auction) }

    before do
      create(:transfer)
    end

    it 'returns transfers by auction' do
      expect(described_class.by_auction(auction.id)).to eq([matched_transfer])
    end
  end

  describe '.all_out' do
    let!(:outgoing_transfer) { create(:transfer, status: :outgoing) }
    let!(:left_transfer) { create(:transfer, status: :left) }

    before do
      create(:transfer, status: :incoming)
    end

    it 'returns outgoing and left transfers' do
      expect(described_class.all_out).to contain_exactly(outgoing_transfer, left_transfer)
    end
  end
end

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

  describe '.recent' do
    let(:league) { create(:league) }
    let!(:oldest) { create(:transfer, league: league, created_at: 3.hours.ago) }
    let!(:newest) { create(:transfer, league: league, created_at: 1.hour.ago) }
    let!(:middle) { create(:transfer, league: league, created_at: 2.hours.ago) }

    it 'returns transfers newest first' do
      expect(league.transfers.recent).to eq([newest, middle, oldest])
    end

    context 'when transfers share the same timestamp' do
      let(:stamp) { 1.hour.ago.change(usec: 0) }
      let!(:oldest) { create(:transfer, league: league, created_at: stamp) }
      let!(:newest) { create(:transfer, league: league, created_at: stamp) }
      let!(:middle) { create(:transfer, league: league, created_at: stamp) }

      it 'falls back to id descending' do
        expect(league.transfers.recent).to eq([middle, newest, oldest])
      end
    end
  end

  describe '.oldest' do
    let(:league) { create(:league) }
    let!(:oldest) { create(:transfer, league: league, created_at: 3.hours.ago) }
    let!(:newest) { create(:transfer, league: league, created_at: 1.hour.ago) }
    let!(:middle) { create(:transfer, league: league, created_at: 2.hours.ago) }

    it 'returns transfers oldest first' do
      expect(league.transfers.oldest).to eq([oldest, middle, newest])
    end
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

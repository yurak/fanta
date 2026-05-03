RSpec.describe PlayerBids::Search do
  describe '#call' do
    subject(:result) { described_class.call(params) }

    let(:auction) { create(:auction) }
    let(:auction_bid) { create(:auction_bid, auction_round: create(:auction_round, auction: auction, number: 1)) }
    let!(:player_bid) { create(:player_bid, auction_bid: auction_bid, player: create(:player, :with_pos_dc), status: :success) }
    let(:params) { { auction_id: auction.id } }

    context 'when filtering by auction' do
      let(:other_auction) { create(:auction) }
      let!(:other_player_bid) do
        create(:player_bid,
               auction_bid: create(:auction_bid, auction_round: create(:auction_round, auction: other_auction, number: 1)),
               player: create(:player, :with_pos_dc),
               status: :success)
      end

      it 'includes bids from the given auction' do
        expect(result.values.flatten).to include(player_bid)
      end

      it 'excludes bids from other auctions' do
        expect(result.values.flatten).not_to include(other_player_bid)
      end
    end

    context 'when player bid is not successful' do
      let!(:initial_bid) { create(:player_bid, auction_bid: auction_bid, player: create(:player, :with_pos_dc), status: :initial) }

      it 'excludes non-success bids' do
        expect(result.values.flatten).not_to include(initial_bid)
      end
    end

    context 'when searching by player name' do
      let!(:matching_bid) do
        create(:player_bid,
               auction_bid: auction_bid,
               player: create(:player, :with_pos_dc, name: 'Messi'),
               status: :success)
      end
      let(:params) { { auction_id: auction.id, search: 'messi' } }

      it 'includes bids matching the search term' do
        expect(result.values.flatten).to include(matching_bid)
      end

      it 'excludes bids not matching the search term' do
        expect(result.values.flatten).not_to include(player_bid)
      end
    end

    context 'when filtering by round' do
      let!(:round2_player_bid) do
        create(:player_bid,
               auction_bid: create(:auction_bid, auction_round: create(:auction_round, auction: auction, number: 2)),
               player: create(:player, :with_pos_dc),
               status: :success)
      end
      let(:params) { { auction_id: auction.id, round: 2 } }

      it 'includes only bids from the specified round' do
        expect(result.values.flatten).to include(round2_player_bid)
      end

      it 'excludes bids from other rounds' do
        expect(result.values.flatten).not_to include(player_bid)
      end
    end

    context 'when filtering by team' do
      let!(:other_team_bid) do
        other_team = create(:team)
        create(:player_bid,
               auction_bid: create(:auction_bid, auction_round: auction_bid.auction_round, team: other_team),
               player: create(:player, :with_pos_dc),
               status: :success)
      end
      let(:params) { { auction_id: auction.id, team_id: auction_bid.team_id } }

      it 'includes bids for the specified team' do
        expect(result.values.flatten).to include(player_bid)
      end

      it 'excludes bids from other teams' do
        expect(result.values.flatten).not_to include(other_team_bid)
      end
    end

    context 'when multiple rounds exist' do
      before do
        create(:player_bid,
               auction_bid: create(:auction_bid, auction_round: create(:auction_round, auction: auction, number: 2)),
               player: create(:player, :with_pos_dc),
               status: :success)
      end

      it 'groups results by round number' do
        expect(result.keys).to contain_exactly(1, 2)
      end

      it 'orders rounds in descending order' do
        expect(result.keys).to eq([2, 1])
      end
    end
  end
end

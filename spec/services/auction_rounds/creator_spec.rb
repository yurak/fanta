RSpec.describe AuctionRounds::Creator do
  describe '#call' do
    subject(:creator) { described_class.call(auction) }

    let(:auction) { create(:auction) }

    context 'without auction' do
      let(:auction) { nil }

      it 'returns false' do
        expect(creator).to be_falsey
      end
    end

    context 'when league without teams' do
      it 'returns false' do
        expect(creator).to be(false)
      end
    end

    context 'when league teams have empty squad' do
      let!(:team_one) { create(:team, league: auction.league) }
      let!(:team_two) { create(:team, league: auction.league) }

      it 'creates one auction_bid with player_bids for team_one' do
        creator

        expect(team_one.auction_bids.count).to eq(1)
      end

      it 'creates 25 player_bids for team_one' do
        creator

        expect(team_one.auction_bids.last.player_bids.count).to eq(25)
      end

      it 'creates one auction_bid with player_bids for team_two' do
        creator

        expect(team_two.auction_bids.count).to eq(1)
      end

      it 'creates 25 player_bids for team_two' do
        creator

        expect(team_two.auction_bids.last.player_bids.count).to eq(25)
      end
    end

    context 'when league teams have few vacancies' do
      let!(:team_one) { create(:team, :with_15_players, league: auction.league) }
      let!(:team_two) { create(:team, :with_20_players, league: auction.league) }

      it 'creates one auction_bid with player_bids for team_one' do
        creator

        expect(team_one.auction_bids.count).to eq(1)
      end

      it 'creates 10 player_bids for team_one' do
        creator

        expect(team_one.auction_bids.last.player_bids.count).to eq(10)
      end

      it 'creates one auction_bid with player_bids for team_two' do
        creator

        expect(team_two.auction_bids.count).to eq(1)
      end

      it 'creates 5 player_bids for team_two' do
        creator

        expect(team_two.auction_bids.last.player_bids.count).to eq(5)
      end
    end

    context 'when league team has full squad' do
      let!(:team_one) { create(:team, :with_15_players, league: auction.league) }
      let!(:team_two) { create(:team, :with_full_squad, league: auction.league) }

      it 'creates one auction_bid with player_bids for team_one' do
        creator

        expect(team_one.auction_bids.count).to eq(1)
      end

      it 'creates 10 player_bids for team_one' do
        creator

        expect(team_one.auction_bids.last.player_bids.count).to eq(10)
      end

      it 'does not create auction_bid for team_two' do
        creator

        expect(team_two.auction_bids.count).to eq(0)
      end
    end
  end
end

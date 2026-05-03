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

    context 'when league teams have empty squad on first round of auction' do
      let!(:team_one) { create(:team, league: auction.league) }
      let!(:team_two) { create(:team, league: auction.league) }

      it 'creates one auction_bid with player_bids for team_one' do
        creator

        expect(team_one.auction_bids.count).to eq(1)
      end

      it 'creates 11 player_bids for team_one' do
        creator

        expect(team_one.auction_bids.last.player_bids.count).to eq(team_one.league.auction_step)
      end

      it 'creates one auction_bid with player_bids for team_two' do
        creator

        expect(team_two.auction_bids.count).to eq(1)
      end

      it 'creates 11 player_bids for team_two' do
        creator

        expect(team_two.auction_bids.last.player_bids.count).to eq(team_one.league.auction_step)
      end
    end

    context 'when league teams have empty squad on second round of auction' do
      let!(:team_one) { create(:team, league: auction.league) }
      let!(:team_two) { create(:team, league: auction.league) }

      before do
        create(:auction_round, auction: auction, number: 1)
      end

      it 'creates one auction_bid with player_bids for team_one' do
        creator

        expect(team_one.auction_bids.count).to eq(1)
      end

      it 'creates 26 player_bids for team_one' do
        creator

        expect(team_one.auction_bids.last.player_bids.count).to eq(Team::MAX_PLAYERS)
      end

      it 'creates one auction_bid with player_bids for team_two' do
        creator

        expect(team_two.auction_bids.count).to eq(1)
      end

      it 'creates 26 player_bids for team_two' do
        creator

        expect(team_two.auction_bids.last.player_bids.count).to eq(Team::MAX_PLAYERS)
      end
    end

    context 'when league teams have few vacancies on intermediate auction' do
      let(:auction) { create(:auction, number: 2) }
      let!(:team_one) { create(:team, :with_15_players, league: auction.league) }
      let!(:team_two) { create(:team, :with_20_players, league: auction.league) }

      it 'creates one auction_bid with player_bids for team_one' do
        creator

        expect(team_one.auction_bids.count).to eq(1)
      end

      it 'creates 11 player_bids for team_one' do
        creator

        expect(team_one.auction_bids.last.player_bids.count).to eq(11)
      end

      it 'creates one auction_bid with player_bids for team_two' do
        creator

        expect(team_two.auction_bids.count).to eq(1)
      end

      it 'creates 6 player_bids for team_two' do
        creator

        expect(team_two.auction_bids.last.player_bids.count).to eq(6)
      end
    end

    context 'when last round deadline is more than 1 day away' do
      let(:far_deadline) { 3.days.from_now }

      before do
        create(:team, league: auction.league)
        create(:auction_round, auction: auction, number: 1, deadline: far_deadline)
      end

      it 'reuses the last round deadline for the new round' do
        creator
        expect(auction.auction_rounds.last.deadline).to be_within(1.second).of(far_deadline)
      end
    end

    context 'when last round deadline is less than 1 day away' do
      let(:near_deadline) { 12.hours.from_now }

      before do
        create(:team, league: auction.league)
        create(:auction_round, auction: auction, number: 1, deadline: near_deadline)
      end

      it 'sets deadline to last round deadline plus 1 day' do
        creator
        expect(auction.auction_rounds.last.deadline).to be_within(1.second).of(near_deadline + 1.day)
      end
    end

    context 'when creating the first round of a primary auction' do
      before { create(:team, league: auction.league) }

      it 'marks the round as basic' do
        creator
        expect(auction.auction_rounds.last.basic).to be(true)
      end
    end

    context 'when creating a subsequent round' do
      before do
        create(:team, league: auction.league)
        create(:auction_round, auction: auction, number: 1)
      end

      it 'does not mark the round as basic' do
        creator
        expect(auction.auction_rounds.last.basic).to be(false)
      end
    end

    context 'when the round is created successfully' do
      before do
        create(:team, league: auction.league)
        allow(Notifications::Creator).to receive(:call)
      end

      it 'sends auction_start_bids notification' do
        creator
        expect(Notifications::Creator).to have_received(:call).with(
          notifiable: auction.auction_rounds.last,
          kind: :auction_start_bids
        )
      end

      it 'returns true' do
        expect(creator).to be(true)
      end
    end

    context 'when league team has full squad on intermediate auction' do
      let(:auction) { create(:auction, number: 2) }
      let!(:team_one) { create(:team, :with_15_players, league: auction.league) }
      let!(:team_two) { create(:team, :with_full_squad, league: auction.league) }

      it 'creates one auction_bid with player_bids for team_one' do
        creator

        expect(team_one.auction_bids.count).to eq(1)
      end

      it 'creates 11 player_bids for team_one' do
        creator

        expect(team_one.auction_bids.last.player_bids.count).to eq(11)
      end

      it 'does not create auction_bid for team_two' do
        creator

        expect(team_two.auction_bids.count).to eq(0)
      end
    end
  end
end

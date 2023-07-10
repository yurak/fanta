RSpec.describe AuctionRound do
  subject(:auction_round) { create(:auction_round) }

  describe 'Associations' do
    it { is_expected.to belong_to(:auction) }
    it { is_expected.to have_many(:auction_bids).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:status).with_values(%i[active processing closed]) }
  end

  describe '#bid_exist?(team)' do
    let!(:team) { create(:team) }

    context 'without auction_bids' do
      it { expect(auction_round.bid_exist?(team)).to be(false) }
    end

    context 'without team' do
      it { expect(auction_round.bid_exist?(nil)).to be(false) }
    end

    context 'without auction_bids of specified team' do
      before do
        create_list(:auction_bid, 3, auction_round: auction_round)
      end

      it { expect(auction_round.bid_exist?(team)).to be(false) }
    end

    context 'with auction_bids of specified team' do
      before do
        create(:auction_bid, auction_round: auction_round, team: team)
      end

      it { expect(auction_round.bid_exist?(team)).to be(true) }
    end
  end

  describe '#members' do
    context 'without teams in league' do
      it 'returns empty array' do
        expect(auction_round.members).to eq([])
      end
    end

    context 'when all league teams have vacancies' do
      let(:league) { create(:league, :with_five_teams) }
      let(:auction) { create(:auction, league: league) }
      let(:auction_round) { create(:auction_round, auction: auction) }

      it 'returns array with teams' do
        expect(auction_round.members).to eq(league.teams)
      end
    end

    context 'when one team is already staffed' do
      let(:league) { create(:league, :with_five_teams) }
      let(:auction) { create(:auction, league: league) }
      let(:auction_round) { create(:auction_round, auction: auction) }

      before do
        create(:team, :with_full_squad, league: league)
      end

      it 'returns array without staffed team' do
        expect(auction_round.members).not_to eq(league.teams)
      end

      it 'returns array with teams which has vacancies' do
        expect(auction_round.members.count).to eq(5)
      end
    end

    context 'when all teams are already staffed' do
      let(:league) { create(:league) }
      let(:auction) { create(:auction, league: league) }
      let(:auction_round) { create(:auction_round, auction: auction) }

      before do
        create_list(:team, 2, :with_full_squad, league: league)
      end

      it 'returns empty array' do
        expect(auction_round.members).to eq([])
      end
    end
  end
end

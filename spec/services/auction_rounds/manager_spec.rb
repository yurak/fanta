RSpec.describe AuctionRounds::Manager do
  describe '#call' do
    subject(:manager) { described_class.new(auction_round) }

    let(:auction_round) { create(:auction_round) }

    context 'with active status and without deadline' do
      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with active status and without league teams' do
      let(:auction_round) { create(:auction_round, deadline: 1.hour.ago) }

      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with active status and not ready bids' do
      let(:auction_round) { create(:auction_round, deadline: 1.hour.ago) }
      let(:league) { auction_round.league }
      let(:teams) { create_list(:team, 4, league: league) }

      before do
        create(:auction_bid, team: teams[0], auction_round: auction_round)
        create(:ongoing_auction_bid, team: teams[1], auction_round: auction_round)
        create(:submitted_auction_bid, team: teams[2], auction_round: auction_round)
        create(:completed_auction_bid, team: teams[3], auction_round: auction_round)
      end

      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with active status, before deadline and when not all bids are completed' do
      let(:auction_round) { create(:auction_round, deadline: 4.hours.from_now) }
      let(:league) { auction_round.league }
      let(:teams) { create_list(:team, 4, league: league) }

      before do
        create(:submitted_auction_bid, team: teams[0], auction_round: auction_round)
        create(:completed_auction_bid, team: teams[1], auction_round: auction_round)
        create(:submitted_auction_bid, team: teams[2], auction_round: auction_round)
        create(:completed_auction_bid, team: teams[3], auction_round: auction_round)
      end

      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with active status and when all bids are completed before deadline' do
      let(:auction_round) { create(:auction_round, number: 1, deadline: 4.hours.from_now) }
      let(:league) { auction_round.league }
      let(:teams) { create_list(:team, 4, league: league) }

      before do
        teams.each { |team| create(:completed_auction_bid, :with_player_bids, team: team, auction_round: auction_round) }
      end

      it 'returns true' do
        expect(manager.call).to be(true)
      end

      context 'when service call' do
        before do
          manager.call
        end

        it 'creates transfers' do
          expect(Transfer.all.count).to eq(24)
        end

        it 'updates player_bids status' do
          expect(teams.last.auction_bids.first.player_bids.last.status).to eq('success')
        end

        it 'updates auction_round status' do
          expect(auction_round.status).to eq('closed')
        end

        it 'updates auction_bids status' do
          expect(auction_round.auction_bids.pluck(:status).uniq).to eq(['processed'])
        end
      end

      context 'with multiple top bids with same price' do
        let(:player) { teams.last.auction_bids.last.player_bids.last.player }
        let!(:player_bid) { create(:player_bid, player: player, auction_bid: teams.first.auction_bids.last) }

        before do
          manager.call
        end

        it 'fails player_bids' do
          expect(player_bid.reload.status).to eq('failed')
        end
      end

      context 'when player already has team in league' do
        let(:player_bid) { teams.last.auction_bids.last.player_bids.last }
        let(:player) { player_bid.player }

        before do
          create(:player_team, team: teams.first, player: player)
          manager.call
        end

        it 'fails player_bids' do
          expect(player_bid.reload.status).to eq('failed')
        end
      end
    end

    context 'with active status and when all bids are ready after deadline' do
      let(:auction_round) { create(:auction_round, number: 1, deadline: 1.hour.ago) }
      let(:league) { auction_round.league }
      let(:teams) { create_list(:team, 4, league: league) }

      before do
        teams.each { |team| create(:submitted_auction_bid, :with_player_bids, team: team, auction_round: auction_round) }
      end

      it 'returns true' do
        expect(manager.call).to be(true)
      end

      context 'when service call' do
        before do
          manager.call
        end

        it 'creates transfers' do
          expect(Transfer.all.count).to eq(24)
        end

        it 'updates player_bids status' do
          expect(teams.last.auction_bids.first.player_bids.last.status).to eq('success')
        end

        it 'updates auction_round status' do
          expect(auction_round.status).to eq('closed')
        end

        it 'updates auction_bids status' do
          expect(auction_round.auction_bids.pluck(:status).uniq).to eq(['processed'])
        end
      end

      context 'with multiple top bids with same price' do
        let(:player) { teams.last.auction_bids.last.player_bids.last.player }
        let!(:player_bid) { create(:player_bid, player: player, auction_bid: teams.first.auction_bids.last) }

        before do
          manager.call
        end

        it 'fails player_bids' do
          expect(player_bid.reload.status).to eq('failed')
        end
      end

      context 'when player already has team in league' do
        let(:player_bid) { teams.last.auction_bids.last.player_bids.last }
        let(:player) { player_bid.player }

        before do
          create(:player_team, team: teams.first, player: player)
          manager.call
        end

        it 'fails player_bids' do
          expect(player_bid.reload.status).to eq('failed')
        end
      end
    end

    context 'with active status and auction bids when some team is already staffed' do
      let(:auction_round) { create(:auction_round, number: 1, deadline: 1.hour.ago) }
      let(:league) { auction_round.league }
      let(:teams) { create_list(:team, 3, league: league) }

      before do
        create(:team, :with_full_squad, league: league)
        teams.each { |team| create(:submitted_auction_bid, :with_player_bids, team: team, auction_round: auction_round) }
      end

      it 'returns true' do
        expect(manager.call).to be(true)
      end

      context 'when service call' do
        before do
          manager.call
        end

        it 'creates transfers' do
          expect(Transfer.all.count).to eq(18)
        end

        it 'updates player_bids status' do
          expect(teams.last.auction_bids.first.player_bids.last.status).to eq('success')
        end

        it 'updates auction_round status' do
          expect(auction_round.status).to eq('closed')
        end

        it 'updates auction_bids status' do
          expect(auction_round.auction_bids.pluck(:status).uniq).to eq(['processed'])
        end
      end

      context 'with multiple top bids with same price' do
        let(:player) { teams.last.auction_bids.last.player_bids.last.player }
        let!(:player_bid) { create(:player_bid, player: player, auction_bid: teams.first.auction_bids.last) }

        before do
          manager.call
        end

        it 'fails player_bids' do
          expect(player_bid.reload.status).to eq('failed')
        end
      end

      context 'when player already has team in league' do
        let(:player_bid) { teams.last.auction_bids.last.player_bids.last }
        let(:player) { player_bid.player }

        before do
          create(:player_team, team: teams.first, player: player)
          manager.call
        end

        it 'fails player_bids' do
          expect(player_bid.reload.status).to eq('failed')
        end
      end
    end

    context 'with processing status' do
      let(:auction_round) { create(:processing_auction_round) }

      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with closed status' do
      let(:auction_round) { create(:closed_auction_round) }

      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end
  end
end

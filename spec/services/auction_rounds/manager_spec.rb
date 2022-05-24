RSpec.describe AuctionRounds::Manager do
  describe '#call' do
    subject(:manager) { described_class.new(auction_round: auction_round) }

    let(:auction_round) { create(:auction_round) }

    context 'with active status and without deadline' do
      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with active status and before deadline' do
      let(:auction_round) { create(:auction_round, deadline: Time.zone.now + 4.hours) }

      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with active status and without league teams' do
      let(:auction_round) { create(:auction_round, deadline: Time.zone.now - 1.hour) }

      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with active status and when not all teams have created auction bids' do
      let(:auction_round) { create(:auction_round, deadline: Time.zone.now - 1.hour) }
      let(:league) { auction_round.league }
      let(:teams) { create_list(:team, 4, league: league) }

      before do
        create(:auction_bid, team: teams.first, auction_round: auction_round)
      end

      it 'returns false' do
        expect(manager.call).to be(false)
      end
    end

    context 'with active status and auction bids' do
      let(:auction_round) { create(:auction_round, number: 1, deadline: Time.zone.now - 1.hour) }
      let(:league) { auction_round.league }
      let(:teams) { create_list(:team, 4, league: league) }

      before do
        teams.each { |team| create(:auction_bid, :with_player_bids, team: team, auction_round: auction_round) }
      end

      it 'returns true' do
        expect(manager.call).to be(true)
      end

      context 'when service call' do
        before do
          manager.call
        end

        it 'creates transfers' do
          expect(Transfer.all.count).to eq(20)
        end

        it 'updates player_bids status' do
          expect(teams.last.auction_bids.last.player_bids.last.status).to eq('success')
        end

        it 'updates auction_round status' do
          expect(auction_round.status).to eq('closed')
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
      let(:auction_round) { create(:auction_round, number: 1, deadline: Time.zone.now - 1.hour) }
      let(:league) { auction_round.league }
      let(:teams) { create_list(:team, 3, league: league) }

      before do
        create(:team, :with_25_players, league: league)
        teams.each { |team| create(:auction_bid, :with_player_bids, team: team, auction_round: auction_round) }
      end

      it 'returns true' do
        expect(manager.call).to be(true)
      end

      context 'when service call' do
        before do
          manager.call
        end

        it 'creates transfers' do
          expect(Transfer.all.count).to eq(15)
        end

        it 'updates player_bids status' do
          expect(teams.last.auction_bids.last.player_bids.last.status).to eq('success')
        end

        it 'updates auction_round status' do
          expect(auction_round.status).to eq('closed')
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

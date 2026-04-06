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

    context 'with active status and not ready bids for primary auction' do
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

    context 'with active status and not ready bids when auction is not primary' do
      let(:auction_round) { create(:auction_round, deadline: 1.hour.ago, auction: create(:auction, number: 2)) }
      let(:league) { auction_round.league }
      let(:teams) { create_list(:team, 4, league: league) }

      before do
        create(:auction_bid, :with_empty_player_bids, team: teams[0], auction_round: auction_round)
        create(:ongoing_auction_bid, :with_player_bids, team: teams[1], auction_round: auction_round)
        create(:submitted_auction_bid, :with_player_bids, team: teams[2], auction_round: auction_round)
        create(:completed_auction_bid, :with_player_bids, team: teams[3], auction_round: auction_round)
      end

      it 'returns true' do
        expect(manager.call).to be(true)
      end

      context 'when service call' do
        before do
          manager.call
        end

        it 'creates transfers' do
          expect(Transfer.count).to eq(18)
        end

        it 'updates player_bids status without player' do
          expect(teams.first.auction_bids.first.player_bids.last.status).to eq('failed')
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

    context 'with active status and when all bids are completed before deadline when round is first and auction is first' do
      let(:auction_round) { create(:auction_round, number: 1, deadline: 4.hours.from_now) }
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

    context 'with active status and when all bids are completed before deadline when auction is first and round is not first' do
      let(:auction_round) { create(:auction_round, number: 2, deadline: 4.hours.from_now) }
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
          expect(Transfer.count).to eq(24)
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

    context 'with active status and when all bids are completed before deadline when auction is not first and round is first' do
      let(:auction_round) { create(:auction_round, auction: create(:auction, number: 2), number: 1, deadline: 4.hours.from_now) }
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
          expect(Transfer.count).to eq(24)
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
          expect(Transfer.count).to eq(24)
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
          expect(Transfer.count).to eq(18)
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

    context 'when a team exceeds its budget' do
      let(:auction_round) { create(:auction_round, deadline: 1.hour.ago, auction: create(:auction, number: 2)) }
      let(:league) { auction_round.league }
      let!(:over_budget_team) { create(:team, league: league) }
      let!(:normal_team) { create(:team, league: league) }
      let!(:over_budget_bid) do
        create(:submitted_auction_bid, :with_player_bids, team: over_budget_team, auction_round: auction_round)
      end

      before do
        over_budget_team.update(budget: 0)
        create(:submitted_auction_bid, :with_player_bids, team: normal_team, auction_round: auction_round)
        manager.call
      end

      it 'fails all initial player_bids for the over-budget team' do
        expect(over_budget_bid.player_bids.map { |pb| pb.reload.status }.uniq).to eq(['failed'])
      end

      it 'does not fail player_bids for the team within budget' do
        normal_bid = normal_team.auction_bids.first
        expect(normal_bid.player_bids.any? { |pb| pb.reload.status == 'success' }).to be(true)
      end
    end

    context 'when no vacancies remain after processing' do
      let(:auction_round) { create(:auction_round, number: 2, deadline: 1.hour.ago, auction: create(:auction, number: 2)) }
      let(:league) { auction_round.league }
      let!(:teams) { create_list(:team, 2, :with_full_squad, league: league) }

      before do
        teams.each { |team| create(:submitted_auction_bid, :with_player_bids, team: team, auction_round: auction_round) }
        allow(Auctions::Manager).to receive(:call)
        allow(AuctionRounds::Creator).to receive(:call)
      end

      it 'calls Auctions::Manager to close the auction' do
        manager.call
        expect(Auctions::Manager).to have_received(:call).with(auction_round.auction, Auctions::Manager::CLOSED_STATUS)
      end

      it 'does not create a new auction round' do
        manager.call
        expect(AuctionRounds::Creator).not_to have_received(:call)
      end
    end

    context 'when no vacancies remain after processing (last round)' do
      let(:auction_round) { create(:auction_round, number: 2, deadline: 1.hour.ago, auction: create(:auction, number: 2)) }
      let(:league) { auction_round.league }
      let!(:home_team) { create(:team, :with_full_squad, league: league, user: create(:user)) }
      let!(:away_team) { create(:team, :with_full_squad, league: league, user: create(:user)) }

      before do
        [home_team, away_team].each { |team| create(:submitted_auction_bid, :with_player_bids, team: team, auction_round: auction_round) }
        allow(Auctions::Manager).to receive(:call)
        manager.call
      end

      it 'does not create auction_squad_complete notifications' do
        expect(Notification.where(notifiable: auction_round, kind: :auction_squad_complete).count).to eq(0)
      end
    end

    context 'when vacancies remain after processing (not the last round)' do
      let(:auction_round) { create(:auction_round, number: 1, deadline: 1.hour.ago) }
      let(:league) { auction_round.league }
      let!(:teams) { create_list(:team, 2, league: league) }

      before do
        teams.each { |team| create(:submitted_auction_bid, :with_player_bids, team: team, auction_round: auction_round) }
        allow(AuctionRounds::Creator).to receive(:call)
        allow(Notifications::Creator).to receive(:call)
        manager.call
      end

      it 'notifies squad complete' do
        expect(Notifications::Creator).to have_received(:call).with(notifiable: auction_round, kind: :auction_squad_complete)
      end
    end

    context 'when a bid does not contain the required number of goalkeepers' do
      let(:auction_round) { create(:auction_round, deadline: 1.hour.ago, auction: create(:auction, number: 2)) }
      let(:league) { auction_round.league }
      let!(:insufficient_gk_team) { create(:team, league: league) }
      let!(:normal_team) { create(:team, league: league) }
      let!(:insufficient_gk_bid) do
        bid = create(:submitted_auction_bid, team: insufficient_gk_team, auction_round: auction_round)
        2.times { create(:player_bid, auction_bid: bid, player: create(:player, :with_pos_por)) }
        create_list(:player_bid, 4, auction_bid: bid)
        bid
      end

      before do
        create(:submitted_auction_bid, :with_player_bids, team: normal_team, auction_round: auction_round)
        manager.call
      end

      it 'fails all initial player_bids for the team with insufficient goalkeepers' do
        expect(insufficient_gk_bid.player_bids.map { |pb| pb.reload.status }.uniq).to eq(['failed'])
      end

      it 'does not fail player_bids for the team with sufficient goalkeepers' do
        normal_bid = normal_team.auction_bids.first
        expect(normal_bid.player_bids.any? { |pb| pb.reload.status == 'success' }).to be(true)
      end
    end

    context 'when existing squad goalkeepers contribute to the minimum' do
      let(:auction_round) { create(:auction_round, deadline: 1.hour.ago, auction: create(:auction, number: 2)) }
      let(:league) { auction_round.league }
      let!(:team) { create(:team, league: league) }
      let!(:other_team) { create(:team, league: league) }

      before do
        gk_player = create(:player, :with_pos_por)
        create(:player_team, player: gk_player, team: team)

        bid = create(:submitted_auction_bid, team: team, auction_round: auction_round)
        2.times { create(:player_bid, auction_bid: bid, player: create(:player, :with_pos_por)) }
        create_list(:player_bid, 4, auction_bid: bid)

        create(:submitted_auction_bid, :with_player_bids, team: other_team, auction_round: auction_round)
        manager.call
      end

      it 'does not fail player_bids when existing squad goalkeepers fill the remaining minimum' do
        bid = team.auction_bids.first
        expect(bid.player_bids.any? { |pb| pb.reload.status == 'success' }).to be(true)
      end
    end

    context 'when a partial bid (1 of 4 slots filled) exceeds budget due to default price on empty slots' do
      # Team budget = 10. One player_bid has price=10, three empty slots have default price=1 each.
      # Total = 10+1+1+1 = 13 > 10 → fail_over_budget_bids fails all player_bids.
      let(:auction_round) { create(:auction_round, deadline: 1.hour.ago, auction: create(:auction, number: 2)) }
      let(:league) { auction_round.league }
      let!(:partial_team) { create(:team, league: league) }
      let!(:normal_team) { create(:team, league: league) }
      let!(:partial_bid) do
        bid = create(:auction_bid, team: partial_team, auction_round: auction_round)
        create(:player_bid, auction_bid: bid, player: create(:player), price: 10)
        create_list(:player_bid, 3, auction_bid: bid, player_id: nil)
        bid
      end

      before do
        partial_team.update(budget: 10)
        create(:submitted_auction_bid, :with_player_bids, team: normal_team, auction_round: auction_round)
        manager.call
      end

      it 'fails all player_bids for the partial team due to budget overrun' do
        expect(partial_bid.player_bids.map { |pb| pb.reload.status }.uniq).to eq(['failed'])
      end

      it 'does not fail player_bids for the team within budget' do
        normal_bid = normal_team.auction_bids.first
        expect(normal_bid.player_bids.any? { |pb| pb.reload.status == 'success' }).to be(true)
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

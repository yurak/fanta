RSpec.describe AuctionsHelper, type: :helper do
  let(:auction) { create(:auction) }

  describe '#auction_link(auction)' do
    context 'with initial auction' do
      it 'returns path' do
        expect(helper.auction_link(auction)).to eq('#')
      end
    end

    context 'with sales auction without current_user' do
      let(:auction) { create(:auction, status: :sales) }

      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'returns path' do
        expect(helper.auction_link(auction)).to eq('#')
      end
    end

    context 'with sales auction and logged user' do
      let(:auction) { create(:auction, status: :sales) }
      let(:user) { create(:user) }
      let!(:team) { create(:team, league: auction.league, user: user) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns path' do
        expect(helper.auction_link(auction)).to eq(edit_team_path(team))
      end
    end

    context 'with blind_bids auction without auction rounds' do
      let(:auction) { create(:auction, status: :blind_bids) }

      it 'returns # path' do
        expect(helper.auction_link(auction)).to eq('#')
      end
    end

    context 'with blind_bids auction with auction rounds' do
      let(:auction) { create(:auction, status: :blind_bids) }
      let!(:auction_round) { create(:auction_round, auction: auction) }

      it 'returns # path' do
        expect(helper.auction_link(auction)).to eq(auction_round_path(auction_round))
      end
    end

    context 'with live auction' do
      let(:auction) { create(:auction, status: :live) }

      it 'returns path' do
        expect(helper.auction_link(auction)).to eq(league_auction_transfers_path(auction.league, auction))
      end
    end

    context 'with closed auction' do
      let(:auction) { create(:auction, status: :closed) }

      it 'returns path' do
        expect(helper.auction_link(auction)).to eq(league_auction_transfers_path(auction.league, auction))
      end
    end
  end

  describe '#auction_message(auction)' do
    context 'with initial auction' do
      it 'returns empty string' do
        expect(helper.auction_message(auction)).to eq('')
      end
    end

    context 'with sales auction without deadline' do
      let(:auction) { create(:auction, status: :sales) }

      it 'returns message without date' do
        expect(helper.auction_message(auction)).to eq(t('auction.sales_msg', date: '--:--'))
      end
    end

    context 'with sales auction with deadline' do
      let(:auction) { create(:auction, status: :sales, deadline: Time.zone.now) }

      it 'returns message with date' do
        expect(helper.auction_message(auction)).to eq(t('auction.sales_msg', date: auction.deadline&.strftime('%H:%M %e/%m/%y')))
      end
    end

    context 'with blind_bids auction without rounds' do
      let(:auction) { create(:auction, status: :blind_bids) }

      it 'returns message without date' do
        expect(helper.auction_message(auction)).to eq(t('auction.blind_bids_msg', date: '--:--'))
      end
    end

    context 'with blind_bids auction without round deadline' do
      let(:auction) { create(:auction, status: :blind_bids) }
      let(:auction_round) { create(:auction_round, auction: auction) }

      it 'returns message without date' do
        expect(helper.auction_message(auction)).to eq(t('auction.blind_bids_msg', date: '--:--'))
      end
    end

    context 'with blind_bids auction with round deadline' do
      let(:auction) { create(:auction, status: :blind_bids) }
      let!(:auction_round) { create(:auction_round, auction: auction, deadline: Time.zone.now) }

      it 'returns message with date' do
        expect(helper.auction_message(auction)).to eq(t('auction.blind_bids_msg', date: auction_round.deadline.strftime('%H:%M %e/%m/%y')))
      end
    end

    context 'with live auction without event_time' do
      let(:auction) { create(:auction, status: :live) }

      it 'returns message without date' do
        expect(helper.auction_message(auction)).to eq(t('auction.live_msg', date: '--:--'))
      end
    end

    context 'with live auction with event_time' do
      let(:auction) { create(:auction, status: :live, event_time: Time.zone.now) }

      it 'returns message with date' do
        expect(helper.auction_message(auction)).to eq(t('auction.live_msg', date: auction.event_time.strftime('%H:%M %e/%m/%y')))
      end
    end
  end

  describe '#user_auction_bid(auction_round, league)' do
    context 'without current_user' do
      let(:auction) { create(:auction) }
      let(:auction_round) { create(:auction_round, auction: auction) }

      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'returns nil' do
        expect(helper.user_auction_bid(auction_round, auction.league)).to be_nil
      end
    end

    context 'with logged user and without auction_bid' do
      let(:auction) { create(:auction) }
      let(:auction_round) { create(:auction_round, auction: auction) }
      let(:user) { create(:user) }

      before do
        create(:team, league: auction.league, user: user)
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns nil' do
        expect(helper.user_auction_bid(auction_round, auction.league)).to be_nil
      end
    end

    context 'with logged user and auction_bid' do
      let(:auction) { create(:auction) }
      let(:auction_round) { create(:auction_round, auction: auction) }
      let(:user) { create(:user) }
      let(:team) { create(:team, league: auction.league, user: user) }
      let!(:auction_bid) { create(:auction_bid, team: team, auction_round: auction_round) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns auction_bid' do
        expect(helper.user_auction_bid(auction_round, auction.league)).to eq(auction_bid)
      end
    end
  end
end

RSpec.describe 'Api::AuctionPurchases' do
  describe 'GET /api/leagues/:league_id/auctions/:auction_id/purchases' do
    subject(:document) do
      get api_league_auction_purchases_path(league_id: league.id, auction_id: auction.id)
      response.parsed_body['data']
    end

    let(:league) { create(:league) }
    let(:auction) { create(:auction, league: league, number: 2) }
    let(:team_a) { create(:team, league: league) }
    let(:team_b) { create(:team, league: league) }
    let!(:team_c) { create(:team, league: league) } # in the league, buys nobody
    let(:teams) { document['teams'] }

    def buy(team, price, status)
      create(:transfer, auction: auction, league: league, team: team,
                        player: create(:player), status: status, price: price)
    end

    before do
      buy(team_a, 30, :incoming)
      buy(team_a, 10, :incoming)
      buy(team_b, 20, :incoming)
      buy(team_b, 8, :outgoing) # a drop, must be excluded from purchases
    end

    it 'returns the auction meta' do
      expect(document['auction']).to include('number' => 2, 'status' => 'initial')
    end

    it 'includes every league team ordered by total spent, excluding drops' do
      expect(teams.pluck('total_spent')).to eq([40, 20, 0])
    end

    context 'when a league member is signed in' do
      let(:team_b) { create(:team, :with_user, league: league) }

      before { sign_in team_b.user }

      it 'puts the current user team first, the rest still by total spent' do
        expect(teams.pluck('total_spent')).to eq([20, 40, 0])
      end
    end

    it 'keeps a team that bought nobody, with an empty list' do
      empty = teams.find { |group| group['team']['id'] == team_c.id }
      aggregate_failures do
        expect(empty['total_spent']).to eq(0)
        expect(empty['bought']).to be_empty
      end
    end

    it 'lists each team bought players sorted by price' do
      aggregate_failures do
        expect(teams.first['team']['id']).to eq(team_a.id)
        expect(teams.first['bought'].pluck('price')).to eq([30, 10])
      end
    end

    it 'ranks top spenders by total spent' do
      expect(document['top_spenders'].first).to include('value' => 40)
    end

    it 'ranks top individual buys by price' do
      expect(document['top_buy'].first['price']).to eq(30)
    end

    it 'returns 404 for an auction outside the league' do
      other = create(:auction, league: create(:league))
      get api_league_auction_purchases_path(league_id: league.id, auction_id: other.id)
      expect(response).to have_http_status(:not_found)
    end
  end
end

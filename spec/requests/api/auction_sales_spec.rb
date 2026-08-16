RSpec.describe 'Api::AuctionSales' do
  describe 'GET /api/leagues/:league_id/auctions/:auction_id/sales' do
    subject(:document) do
      get api_league_auction_sales_path(league_id: league.id, auction_id: auction.id)
      response.parsed_body['data']
    end

    let(:league) { create(:league) }
    let(:auction) { create(:auction, league: league, number: 2) }
    let(:team_a) { create(:team, league: league) }
    let(:team_b) { create(:team, league: league) }
    let!(:team_c) { create(:team, league: league) } # in the league, drops nobody
    let(:teams) { document['teams'] }

    def drop(team, price, status)
      create(:transfer, auction: auction, league: league, team: team,
                        player: create(:player), status: status, price: price)
    end

    before do
      drop(team_a, 30, :outgoing)
      drop(team_a, 10, :outgoing)
      drop(team_a, 5, :left)
      drop(team_b, 20, :outgoing)
      drop(team_b, 8, :incoming) # incoming is a buy, must be excluded from results
    end

    it 'returns the auction meta' do
      expect(document['auction']).to include('number' => 2, 'status' => 'initial')
    end

    it 'includes every league team ordered by net income, excluding buys' do
      expect(teams.pluck('net_income')).to eq([45, 20, 0])
    end

    context 'when a league member is signed in' do
      let(:team_b) { create(:team, :with_user, league: league) }

      before { sign_in team_b.user }

      it 'puts the current user team first, the rest still by net income' do
        expect(teams.pluck('net_income')).to eq([20, 45, 0])
      end
    end

    it 'keeps a team that dropped nobody, with an empty list' do
      empty = teams.find { |group| group['team']['id'] == team_c.id }
      aggregate_failures do
        expect(empty['net_income']).to eq(0)
        expect(empty['dropped']).to be_empty
      end
    end

    it 'splits each team group into dropped and left' do
      aggregate_failures do
        expect(teams.first['team']['id']).to eq(team_a.id)
        expect(teams.first['dropped'].size).to eq(2)
        expect(teams.first['left'].size).to eq(1)
      end
    end

    it 'ranks top earners by net income' do
      expect(document['top_earners'].first).to include('value' => 45)
    end

    it 'ranks top droppers by number of departures' do
      expect(document['top_droppers'].first).to include('value' => 3) # team_a: 2 outgoing + 1 left
    end

    it 'ranks top individual sales by price' do
      expect(document['top_sale'].first['price']).to eq(30)
    end

    it 'returns 404 for an auction outside the league' do
      other = create(:auction, league: create(:league))
      get api_league_auction_sales_path(league_id: league.id, auction_id: other.id)
      expect(response).to have_http_status(:not_found)
    end
  end
end

require 'swagger_helper'

RSpec.describe 'Api::AuctionPurchases' do
  transfer_schema = {
    type: :object,
    properties: {
      id: { type: :integer },
      price: { type: :integer },
      status: { type: :string },
      player: { type: :object },
      team: { type: :object }
    }
  }
  ranking_schema = { type: :object, properties: { team: { type: :object }, value: { type: :integer } } }

  path '/api/leagues/{league_id}/auctions/{auction_id}/purchases' do
    parameter name: 'league_id', in: :path, type: :string, description: 'League id'
    parameter name: 'auction_id', in: :path, type: :string, description: 'Auction id'

    get('purchases — bought players per team, with rankings') do
      tags 'Auction Purchases'
      produces 'application/json'

      response 200, 'Success' do
        let(:league) { create(:league) }
        let(:auction) { create(:auction, league: league, number: 2) }
        let(:team_a) { create(:team, league: league) }
        let(:team_b) { create(:team, league: league) }
        let(:league_id) { league.id }
        let(:auction_id) { auction.id }

        before do # rubocop:disable RSpec/ScatteredSetup
          sign_in create(:user)
          create(:team, league: league) # a league team that bought nobody
          buy(team_a, 30, :incoming)
          buy(team_a, 10, :incoming)
          buy(team_b, 20, :incoming)
          buy(team_b, 8, :outgoing) # a drop — excluded from purchases
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     auction: { type: :object },
                     teams: {
                       type: :array,
                       items: {
                         type: :object,
                         properties: {
                           team: { type: :object },
                           total_spent: { type: :integer },
                           bought: { type: :array, items: transfer_schema }
                         }
                       }
                     },
                     top_spenders: { type: :array, items: ranking_schema },
                     top_buy: { type: :array, items: transfer_schema }
                   }
                 }
               }

        run_test! do |response|
          data = JSON.parse(response.body)['data']
          aggregate_failures do
            expect(data['auction']).to include('number' => 2)
            expect(data['teams'].pluck('total_spent')).to eq([40, 20, 0])
            expect(data['teams'].last).to include('total_spent' => 0, 'bought' => [])
            expect(data['top_spenders'].first).to include('value' => 40)
            expect(data['top_buy'].first['price']).to eq(30)
          end
        end
      end

      response 404, 'Auction not in the league' do
        let(:league) { create(:league) }
        let(:league_id) { league.id }
        let(:auction_id) { create(:auction, league: create(:league)).id }

        before { sign_in create(:user) } # rubocop:disable RSpec/ScatteredSetup

        schema '$ref' => '#/components/schemas/error_not_found'

        run_test!
      end
    end
  end

  # extra behavioural coverage (not part of the OpenAPI document)
  describe 'GET purchases ordering' do
    let(:league) { create(:league) }
    let(:auction) { create(:auction, league: league, number: 2) }
    let(:team_b) { create(:team, :with_user, league: league) }

    before do
      buy(create(:team, league: league), 40, :incoming)
      buy(team_b, 20, :incoming)
      sign_in team_b.user
    end

    it 'puts the current user team first, the rest by total spent' do
      get api_league_auction_purchases_path(league_id: league.id, auction_id: auction.id)
      expect(response.parsed_body.dig('data', 'teams').pluck('total_spent')).to eq([20, 40])
    end
  end

  def buy(team, price, status)
    create(:transfer, auction: auction, league: league, team: team, player: create(:player), status: status, price: price)
  end
end

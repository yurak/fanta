require 'swagger_helper'

RSpec.describe 'Api::AuctionSales' do
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

  path '/api/leagues/{league_id}/auctions/{auction_id}/sales' do
    parameter name: 'league_id', in: :path, type: :string, description: 'League id'
    parameter name: 'auction_id', in: :path, type: :string, description: 'Auction id'

    get('sale results — dropped and left players per team, with rankings') do
      tags 'Auction Sales'
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
          create(:team, league: league) # a league team that dropped nobody
          drop(team_a, 30, :outgoing)
          drop(team_a, 10, :outgoing)
          drop(team_a, 5, :left)
          drop(team_b, 20, :outgoing)
          drop(team_b, 8, :incoming) # a buy — excluded from sale results
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
                           net_income: { type: :integer },
                           dropped: { type: :array, items: transfer_schema },
                           left: { type: :array, items: transfer_schema }
                         }
                       }
                     },
                     top_earners: { type: :array, items: ranking_schema },
                     top_droppers: { type: :array, items: ranking_schema },
                     top_sale: { type: :array, items: transfer_schema }
                   }
                 }
               }

        run_test! do |response|
          data = JSON.parse(response.body)['data']
          aggregate_failures do
            expect(data['auction']).to include('number' => 2, 'status' => 'initial')
            expect(data['teams'].pluck('net_income')).to eq([45, 20, 0])
            expect(data['teams'].last).to include('net_income' => 0, 'dropped' => [])
            expect(data['top_earners'].first).to include('value' => 45)
            expect(data['top_droppers'].first).to include('value' => 3)
            expect(data['top_sale'].first['price']).to eq(30)
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
  describe 'GET sale results ordering' do
    let(:league) { create(:league) }
    let(:auction) { create(:auction, league: league, number: 2) }
    let(:team_b) { create(:team, :with_user, league: league) }

    before do
      drop(create(:team, league: league), 45, :outgoing)
      drop(team_b, 20, :outgoing)
      sign_in team_b.user
    end

    it 'puts the current user team first, the rest by net income' do
      get api_league_auction_sales_path(league_id: league.id, auction_id: auction.id)
      expect(response.parsed_body.dig('data', 'teams').pluck('net_income')).to eq([20, 45])
    end
  end

  def drop(team, price, status)
    create(:transfer, auction: auction, league: league, team: team, player: create(:player), status: status, price: price)
  end
end

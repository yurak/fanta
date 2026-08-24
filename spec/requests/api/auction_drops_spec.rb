require 'swagger_helper'

RSpec.describe 'Api::AuctionDrops' do # rubocop:disable RSpec/MultipleMemoizedHelpers
  drop_player_schema = {
    type: :object,
    properties: {
      id: { type: :integer },
      name: { type: :string },
      status: { type: :string, enum: %w[untouchable transferable left] },
      price: { type: :integer, nullable: true },
      appearances: { type: :integer },
      player_team_id: { type: :integer, nullable: true },
      positions: { type: :array, items: { type: :string } },
      form: { type: :array, items: { type: :object } }
    }
  }
  team_schema = {
    type: :object,
    properties: {
      budget: { type: :integer },
      income: { type: :integer },
      possible_budget: { type: :integer },
      players_dropped: { type: :integer },
      players_left: { type: :integer },
      available_transfers: { type: :integer }
    }
  }

  path '/api/leagues/{league_id}/auctions/{auction_id}/drops' do
    parameter name: 'league_id', in: :path, type: :string, description: 'League id'
    parameter name: 'auction_id', in: :path, type: :string, description: 'Auction id'

    get('drop page — the signed-in user squad with drop status (sales phase only)') do
      tags 'Auction Drops'
      produces 'application/json'

      response 200, 'Success' do
        let(:league) { create(:league) }
        let(:auction) { create(:auction, league: league, status: :sales, number: league.auction_number) }
        let(:team) { create(:team, :with_user, league: league, budget: 250, transfer_slots: 5) }
        let(:league_id) { league.id }
        let(:auction_id) { auction.id }

        before do # rubocop:disable RSpec/ScatteredSetup
          player = create(:player)
          create(:player_team, team: team, player: player, transfer_status: :untouchable)
          create(:transfer, team: team, player: player, league: league, auction: auction, status: :incoming, price: 30)
          sign_in team.user
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     auction: { type: :object },
                     team: team_schema,
                     players: { type: :array, items: drop_player_schema }
                   }
                 }
               }

        run_test! do |response|
          data = JSON.parse(response.body)['data']
          aggregate_failures do
            expect(data['team']).to include('budget' => 250, 'available_transfers' => 5, 'players_left' => 0)
            expect(data['players'].first).to include('status' => 'untouchable', 'price' => 30)
          end
        end
      end

      response 404, 'Not the user team or not in the sales phase' do
        let(:league) { create(:league) }
        let(:auction) { create(:auction, league: league, status: :initial, number: league.auction_number) }
        let(:team) { create(:team, :with_user, league: league) }
        let(:league_id) { league.id }
        let(:auction_id) { auction.id }

        before { sign_in team.user } # rubocop:disable RSpec/ScatteredSetup

        schema '$ref' => '#/components/schemas/error_not_found'

        run_test!
      end
    end

    patch('update the drop selection (idempotent set of player ids to sell)') do
      tags 'Auction Drops'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: { player_ids: { type: :array, items: { type: :integer } } }
      }

      response 200, 'Updated' do
        let(:league) { create(:league) }
        let(:auction) { create(:auction, league: league, status: :sales, number: league.auction_number) }
        let(:team) { create(:team, :with_user, league: league, budget: 250, transfer_slots: 5) }
        let(:target) { create(:player) }
        let(:league_id) { league.id }
        let(:auction_id) { auction.id }
        let(:body) { { player_ids: [target.id] } }

        before do # rubocop:disable RSpec/ScatteredSetup
          create(:player_team, team: team, player: target, transfer_status: :untouchable)
          create(:transfer, team: team, player: target, league: league, auction: auction, status: :incoming, price: 30)
          sign_in team.user
        end

        schema type: :object, properties: { data: { type: :object } }

        run_test! do |response|
          data = JSON.parse(response.body)['data']
          aggregate_failures do
            expect(PlayerTeam.find_by(player: target, team: team).transfer_status).to eq('transferable')
            expect(data['team']['possible_budget']).to eq(280)
          end
        end
      end

      response 422, 'Transfer limit exceeded' do
        let(:league) { create(:league) }
        let(:auction) { create(:auction, league: league, status: :sales, number: league.auction_number) }
        let(:team) { create(:team, :with_user, league: league, budget: 250, transfer_slots: 1) }
        let(:squad) { create_list(:player, 2) }
        let(:league_id) { league.id }
        let(:auction_id) { auction.id }
        let(:body) { { player_ids: squad.map(&:id) } }

        before do # rubocop:disable RSpec/ScatteredSetup
          squad.each do |player|
            create(:player_team, team: team, player: player, transfer_status: :untouchable)
            create(:transfer, team: team, player: player, league: league, auction: auction, status: :incoming, price: 10)
          end
          sign_in team.user
        end

        run_test! do
          expect(PlayerTeam.where(team: team, transfer_status: :transferable)).to be_empty
        end
      end
    end
  end
end

require 'swagger_helper'

RSpec.describe 'Player Bids' do
  path '/api/player_bids/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'Player bid id'

    get('show player bid') do
      tags 'Player Bids'
      consumes 'application/json'
      produces 'application/json'

      response 200, 'Success' do
        let!(:auction_round) { create(:auction_round, number: 1, auction: create(:auction, status: :closed)) }
        let!(:player_bid) { create(:player_bid, status: :success, auction_bid: create(:auction_bid, auction_round: auction_round)) }
        let!(:player_bid_failed) do
          create(:player_bid, status: :failed, player: player_bid.player, auction_bid: create(:auction_bid, auction_round: auction_round))
        end
        let!(:id) { player_bid.id }

        schema type: :object,
               properties: {
                 data: { '$ref' => '#/components/schemas/player_bid' }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['id']).to eq id
          expect(body['data']['player']['id']).to eq player_bid.player.id
          expect(body['data']['auction_bids']['1'].count).to eq 2
          expect(body['data']['auction_bids']['1'].first['id']).to eq id
          expect(body['data']['auction_bids']['1'].first['status']).to eq 'success'
          expect(body['data']['auction_bids']['1'].last['id']).to eq player_bid_failed.id
        end
      end

      response 404, 'Not found', document: false do
        let!(:player_bid) { create(:player_bid, status: :success) }
        let!(:id) { player_bid.id }

        schema '$ref' => '#/components/schemas/error_not_found'

        run_test!
      end

      response 404, 'Not found' do
        let!(:id) { 'invalid' }

        schema '$ref' => '#/components/schemas/error_not_found'

        run_test!
      end
    end
  end
end

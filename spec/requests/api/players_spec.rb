require 'swagger_helper'

RSpec.describe 'Players' do
  path '/api/players' do
    get('list players') do
      tags 'Players'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :filter, in: :query, type: :object, required: false, schema: {
        type: :object,
        properties: {
          club_id: { type: :integer, example: 123 },
          league_id: { type: :integer, example: 123 },
          name: { type: :string, example: 'David' },
          position: { type: :string, example: 'RB' },
          tournament_id: { type: :integer, example: 123 }
        }
      }
      parameter name: :page, in: :query, type: :object, required: false, schema: {
        type: :object,
        properties: {
          number: { type: :integer, example: 1 },
          size: { type: :integer, example: 30 }
        }
      }

      let!(:player_one) { create(:player) }
      let!(:player_two) { create(:player) }

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 data: { type: :array, items: { '$ref' => '#/components/schemas/player_base' } }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 2
          expect(body['data'].pluck('id')).to contain_exactly(player_one.id, player_two.id)
          expect(body['meta']['size']).to eq 2
          expect(body['meta']['page']['per_page']).to eq 30
          expect(body['meta']['page']['total_pages']).to eq 1
          expect(body['meta']['page']['current_page']).to eq 1
        end
      end
    end
  end

  path '/api/players/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'Player id'

    get('show player') do
      tags 'Players'
      consumes 'application/json'
      produces 'application/json'

      response 200, 'Success' do
        let!(:player) { create(:player, :with_national_team, :with_team) }
        let!(:id) { player.id }

        schema type: :object,
               properties: {
                 data: { '$ref' => '#/components/schemas/player' }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['id']).to eq id
          expect(body['data']['name']).to eq player.name
        end
      end

      response 404, 'Not found' do
        let!(:id) { 'invalid' }

        schema '$ref' => '#/components/schemas/error_not_found'

        run_test!
      end
    end
  end
end

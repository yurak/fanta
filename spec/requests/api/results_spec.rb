require 'swagger_helper'

RSpec.describe 'Results' do
  path '/api/leagues/{league_id}/results' do
    parameter name: 'league_id', in: :path, type: :string, description: 'League id'

    get('list league results') do
      tags 'Results'
      consumes 'application/json'
      produces 'application/json'

      response 200, 'Success' do
        let!(:league) { create(:league) }
        let!(:results) { create_list(:result, 4, league: league) }
        let!(:league_id) { league.id }

        schema type: :object,
               properties: {
                 data: { type: :array, items: { '$ref' => '#/components/schemas/result' } }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].first['league_id']).to eq league_id
          expect(body['data'].count).to eq results.count
        end
      end

      response 404, 'Not found' do
        let!(:league_id) { 'invalid' }

        schema '$ref' => '#/components/schemas/error_not_found'

        run_test!
      end
    end
  end
end

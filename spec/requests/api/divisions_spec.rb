require 'swagger_helper'

RSpec.describe 'Divisions' do
  path '/api/tournaments/{tournament_id}/divisions' do
    parameter name: 'tournament_id', in: :path, type: :string, description: 'Tournament id'
    parameter name: 'season_id', in: :query, type: :string, required: false, description: 'Season id'

    get('list tournament divisions') do
      tags 'Divisions'
      consumes 'application/json'
      produces 'application/json'

      response 200, 'Success' do
        let!(:tournament) { create(:tournament) }
        let!(:division) { create(:division, level: 'A') }
        let!(:league) { create(:league, tournament: tournament, division: division) }
        let(:tournament_id) { tournament.id }

        schema type: :object,
               properties: {
                 data: { type: :array, items: { '$ref' => '#/components/schemas/division' } }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].first['id']).to eq division.id
          expect(body['data'].first['leagues'].first['id']).to eq league.id
        end
      end

      response 404, 'Not found' do
        let(:tournament_id) { 'invalid' }

        schema '$ref' => '#/components/schemas/error_not_found'

        run_test!
      end
    end
  end
end

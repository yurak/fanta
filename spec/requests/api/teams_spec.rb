require 'swagger_helper'

RSpec.describe 'Teams' do
  path '/api/teams/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'Team id'

    get('show team') do
      tags 'Teams'
      consumes 'application/json'
      produces 'application/json'

      response 200, 'Success' do
        let!(:team) { create(:team) }
        let!(:player_team) { create(:player_team, team: team) }
        let!(:id) { team.id }

        schema type: :object,
               properties: {
                 data: { '$ref' => '#/components/schemas/team' }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['id']).to eq id
          expect(body['data']['human_name']).to eq team.human_name
          expect(body['data']['players']).to contain_exactly(player_team.player_id)
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

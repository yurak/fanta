require 'swagger_helper'

RSpec.describe 'Leagues' do
  path '/api/leagues' do
    get('list leagues') do
      tags 'Leagues'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :filter, in: :query, style: 'deepObject', type: :object, required: false, schema: {
        type: :object,
        properties: {
          season_id: { type: :integer, example: 123 },
          tournament_id: { type: :integer, example: 123 }
        }
      }

      let!(:league_one) { create(:active_league, tournament: create(:tournament), season: create(:season)) }
      let(:league_two) { create(:league) }
      let!(:league_three) { create(:active_league, tournament: create(:tournament), season: create(:season)) }

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 data: { type: :array, items: { '$ref' => '#/components/schemas/league_base' } }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 2
          expect(body['data'].pluck('id')).to contain_exactly(league_one.id, league_three.id)
        end
      end

      response 200, 'Filtered by tournament_id', document: false do
        let(:filter) { { tournament_id: league_one.tournament_id } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].pluck('id')).to contain_exactly(league_one.id)
        end
      end

      response 200, 'Filtered by season_id', document: false do
        let(:filter) { { season_id: league_one.season_id } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].pluck('id')).to contain_exactly(league_one.id)
        end
      end
    end
  end

  path '/api/leagues/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'League id'

    get('show league') do
      tags 'Leagues'
      consumes 'application/json'
      produces 'application/json'

      response 200, 'Success' do
        let!(:league) { create(:league) }
        let!(:id) { league.id }

        schema type: :object,
               properties: {
                 data: { '$ref' => '#/components/schemas/league' }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['id']).to eq id
          expect(body['data']['name']).to eq league.name
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

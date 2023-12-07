require 'swagger_helper'

RSpec.describe 'Tournaments', type: :request do
  path '/api/tournaments' do
    get('list tournaments') do
      tags 'Tournaments'
      consumes 'application/json'
      produces 'application/json'

      let!(:tournament_one) { create(:tournament, :with_clubs) }
      let!(:tournament_two) { create(:tournament, :with_clubs) }

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 data: { type: :array, items: { '$ref' => '#/components/schemas/tournament' } }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 2
          expect(body['data'].pluck('id')).to match_array [tournament_one.id, tournament_two.id]
        end
      end
    end
  end
end

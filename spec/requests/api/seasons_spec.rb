require 'swagger_helper'

RSpec.describe 'Seasons' do
  path '/api/seasons' do
    get('list seasons') do
      tags 'Seasons'
      consumes 'application/json'
      produces 'application/json'

      let!(:season_one) { Season.first }
      let!(:season_two) { create(:season) }

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 data: { type: :array, items: { '$ref' => '#/components/schemas/season' } }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 2
          expect(body['data'].pluck('id')).to contain_exactly(season_one.id, season_two.id)
        end
      end
    end
  end
end

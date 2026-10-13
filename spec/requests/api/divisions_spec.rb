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
        let!(:league) { create(:league, :with_five_teams, tournament: tournament, division: division) }
        let(:tournament_id) { tournament.id }

        schema type: :object,
               properties: {
                 data: { type: :array, items: { '$ref' => '#/components/schemas/division' } },
                 meta: {
                   type: :object,
                   properties: {
                     season_id: { type: :integer, example: 8 },
                     my_league_ids: { type: :array, items: { type: :integer }, example: [123] },
                     my_team_ids: { type: :array, items: { type: :integer }, example: [321] }
                   }
                 }
               }

        run_test! do |response|
          body = JSON.parse(response.body)
          serialized = body['data'].first['leagues'].first

          expect(body['data'].first['id']).to eq division.id
          expect(serialized['id']).to eq league.id
        end
      end

      # The page paints the promotion and relegation chips off these two, so they have to travel
      # with the league rather than be looked up per row.
      response 200, 'Carries the zone sizes and the standings in order' do
        let!(:tournament) { create(:tournament) }
        let!(:division) { create(:division, level: 'A') }
        let!(:league) do
          create(:league, tournament: tournament, division: division, promotion: 2, relegation: 1)
        end
        let(:tournament_id) { tournament.id }

        before do
          [3, 10, 7].each { |points| create(:result, league: league, team: create(:team, league: league), points: points) }
        end

        schema type: :object, properties: { data: { type: :array } }

        run_test! do |response|
          serialized = JSON.parse(response.body)['data'].first['leagues'].first

          aggregate_failures do
            expect(serialized['promotion']).to eq 2
            expect(serialized['relegation']).to eq 1
            expect(serialized['results'].pluck('points')).to eq [10, 7, 3]
          end
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

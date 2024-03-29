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
          app: {
            type: :object,
            properties: {
              max: { type: :integer, example: 15 },
              min: { type: :integer, example: 3 }
            }
          },
          base_score: {
            type: :object,
            properties: {
              max: { type: :float, example: 7.89 },
              min: { type: :float, example: 6.78 }
            }
          },
          club_id: { type: :array, items: { type: :integer, example: 44 }, example: [44, 55] },
          league_id: { type: :integer, example: 123 },
          name: { type: :string, example: 'David' },
          position: { type: :array, items: { type: :string, example: 'RB' }, example: %w[RB WB] },
          team_id: { type: :array, items: { type: :integer, example: 44 }, example: [44, 55] },
          total_score: {
            type: :object,
            properties: {
              max: { type: :float, example: 7.89 },
              min: { type: :float, example: 6.78 }
            }
          },
          tournament_id: { type: :array, items: { type: :integer, example: 44 }, example: [44, 55] },
          without_team: { type: :boolean, example: true }
        }
      }
      parameter name: :page, in: :query, type: :object, required: false, schema: {
        type: :object,
        properties: {
          number: { type: :integer, example: 1 },
          size: { type: :integer, example: 30 }
        }
      }
      parameter name: :order, in: :query, type: :object, required: false, schema: {
        type: :object,
        properties: {
          field: { type: :string, example: 'total_score',
                   description: 'Available options: name, appearances, base_score, total_score, club, position' },
          direction: { type: :string, example: 'asc', description: 'Available options: asc, desc' }
        }
      }

      let!(:player_one) { create(:player, name: 'Xavi') }
      let!(:player_two) { create(:player, name: 'Anelka') }

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

  path '/api/players/{id}/stats' do
    parameter name: 'id', in: :path, type: :string, description: 'Player id'

    get('show player statistic data') do
      tags 'Players'
      consumes 'application/json'
      produces 'application/json'

      response 200, 'Success' do
        let!(:player) { create(:player) }
        let!(:id) { player.id }

        schema type: :object,
               properties: {
                 data: { '$ref' => '#/components/schemas/player_stats' }
               }

        before do
          create(:player_season_stat, player: player, tournament: player.club.tournament)
          create(:season)
          create(:round_player, player: player, tournament_round: create(:tournament_round, tournament: player.club.tournament), score: 6)
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['id']).to eq id
          expect(body['data']['round_stats'].count).to eq 1
          expect(body['data']['season_stats'].count).to eq 1
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

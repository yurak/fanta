require 'swagger_helper'

RSpec.describe 'Players' do # rubocop:disable RSpec/MultipleMemoizedHelpers
  path '/api/players' do
    get('list players') do
      tags 'Players'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :filter, in: :query, style: 'deepObject', type: :object, required: false, schema: {
        type: :object,
        properties: {
          app: {
            type: :object,
            properties: {
              max: { type: :integer, example: 15 },
              min: { type: :integer, example: 3 }
            }
          },
          minutes: {
            type: :object,
            properties: {
              max: { type: :integer, example: 270 },
              min: { type: :integer, example: 90 }
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
          without_team: { type: :boolean, example: true },
          teams_count: {
            type: :object,
            properties: {
              max: { type: :integer, example: 5 },
              min: { type: :integer, example: 1 }
            }
          },
          price: {
            type: :object,
            properties: {
              max: { type: :float, example: 50.0 },
              min: { type: :float, example: 10.0 }
            }
          }
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

      let!(:league) { create(:active_league, tournament: create(:tournament)) }
      let!(:player_one) { create(:player, name: 'Xavi', club: create(:club, tournament: league.tournament)) }
      let!(:player_two) { create(:player, name: 'Anelka', club: create(:club, tournament: create(:tournament))) }

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
          expect(body['meta']['page']['per_page']).to eq 2
          expect(body['meta']['page']['total_pages']).to eq 1
          expect(body['meta']['page']['current_page']).to eq 1
        end
      end

      response 200, 'Success', document: false do
        let(:order) { { order: { field: 'name' } } }

        schema type: :object,
               properties: {
                 data: { type: :array, items: { '$ref' => '#/components/schemas/player_base' } }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 2
          expect(body['data'].pluck('id')).to contain_exactly(player_one.id, player_two.id)
          expect(body['meta']['size']).to eq 2
          expect(body['meta']['page']['per_page']).to eq 2
          expect(body['meta']['page']['total_pages']).to eq 1
          expect(body['meta']['page']['current_page']).to eq 1
        end
      end

      response 200, 'Filtered by league_id', document: false do
        let(:filter) { { league_id: league.id } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_one.id
        end
      end

      response 200, 'Returns empty result when no players match filter', document: false do
        let(:filter) { { name: 'zzznomatch' } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']).to be_empty
          expect(body['meta']['size']).to eq 0
        end
      end

      response 200, 'Filtered by name', document: false do
        let(:filter) { { name: 'xav' } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_one.id
        end
      end

      response 200, 'Filtered by tournament_id', document: false do
        let(:filter) { { tournament_id: [league.tournament.id] } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_one.id
        end
      end

      response 200, 'Filtered by without_team (requires league_id)', document: false do
        let!(:player_with_team) { create(:player, club: create(:club, tournament: league.tournament)) }
        before do # rubocop:disable RSpec/ScatteredSetup
          team = create(:team, league: league)
          create(:player_team, player: player_with_team, team: team)
        end

        let(:filter) { { league_id: league.id, without_team: true } }

        run_test! do |response|
          body = JSON.parse(response.body)

          ids = body['data'].pluck('id')
          expect(ids).to include(player_one.id)
          expect(ids).not_to include(player_with_team.id)
        end
      end

      response 200, 'Filtered by minutes', document: false do
        let!(:player_with_minutes) { create(:player, club: create(:club, tournament: league.tournament)) }

        before do # rubocop:disable RSpec/ScatteredSetup
          create(:player_season_stat, player: player_with_minutes, club: player_with_minutes.club,
                                      season: Season.last, tournament: league.tournament,
                                      played_minutes: 270)
        end

        let(:filter) { { league_id: league.id, minutes: { min: 100 } } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_with_minutes.id
        end
      end

      response 200, 'Filtered by club_id', document: false do
        let(:filter) { { club_id: [player_one.club_id] } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_one.id
        end
      end

      response 200, 'Filtered by position', document: false do
        let!(:player_with_pos) { create(:player, :with_pos_dc, club: create(:club, tournament: league.tournament)) }
        let(:filter) { { position: ['CB'] } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_with_pos.id
        end
      end

      response 200, 'Filtered by team_id (requires league_id)', document: false do
        let!(:player_in_team) { create(:player, club: create(:club, tournament: league.tournament)) }
        let(:team) { create(:team, league: league) }

        before { create(:player_team, player: player_in_team, team: team) } # rubocop:disable RSpec/ScatteredSetup

        let(:filter) { { league_id: league.id, team_id: [team.id] } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_in_team.id
        end
      end

      response 200, 'Filtered by min app', document: false do
        let!(:player_with_apps) { create(:player, club: create(:club, tournament: league.tournament)) }

        before do # rubocop:disable RSpec/ScatteredSetup
          create(:player_season_stat, player: player_with_apps, club: player_with_apps.club,
                                      season: Season.last, tournament: league.tournament,
                                      played_matches: 10)
        end

        let(:filter) { { app: { min: 5 } } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_with_apps.id
        end
      end

      response 200, 'Filtered by min base_score', document: false do
        let!(:player_with_score) { create(:player, club: create(:club, tournament: league.tournament)) }

        before do # rubocop:disable RSpec/ScatteredSetup
          create(:player_season_stat, player: player_with_score, club: player_with_score.club,
                                      season: Season.last, tournament: league.tournament,
                                      score: 7.5)
        end

        let(:filter) { { base_score: { min: 7.0 } } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_with_score.id
        end
      end

      response 200, 'Filtered by min total_score', document: false do
        let!(:player_with_score) { create(:player, club: create(:club, tournament: league.tournament)) }

        before do # rubocop:disable RSpec/ScatteredSetup
          create(:player_season_stat, player: player_with_score, club: player_with_score.club,
                                      season: Season.last, tournament: league.tournament,
                                      final_score: 8.0)
        end

        let(:filter) { { total_score: { min: 7.0 } } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_with_score.id
        end
      end

      response 200, 'Filtered by min price (requires league_id)', document: false do
        let!(:cheap_player) { create(:player, club: create(:club, tournament: league.tournament)) }
        let!(:expensive_player) { create(:player, club: create(:club, tournament: league.tournament)) }
        let(:team) { create(:team, league: league) }

        before do # rubocop:disable RSpec/ScatteredSetup
          create(:player_team, player: cheap_player, team: team)
          create(:transfer, player: cheap_player, team: team, price: 10, status: :incoming)
          create(:player_team, player: expensive_player, team: team)
          create(:transfer, player: expensive_player, team: team, price: 50, status: :incoming)
        end

        let(:filter) { { league_id: league.id, price: { min: 30 } } }

        run_test! do |response|
          body = JSON.parse(response.body)

          ids = body['data'].pluck('id')
          expect(ids).to include(expensive_player.id)
          expect(ids).not_to include(cheap_player.id)
        end
      end

      response 200, 'Filtered by min teams_count', document: false do
        let!(:player_with_team) { create(:player, :with_team, club: create(:club, tournament: league.tournament)) }
        let(:filter) { { teams_count: { min: 1 } } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['data'].first['id']).to eq player_with_team.id
        end
      end

      response 200, 'With page param returns paginated result', document: false do
        let(:page) { { page: { number: 1, size: 1 } } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq 1
          expect(body['meta']['page']['per_page']).to eq 1
          expect(body['meta']['page']['total_pages']).to eq 2
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

        before do # rubocop:disable RSpec/ScatteredSetup
          season = create(:season)
          create(:player_season_stat, player: player, tournament: player.club.tournament, season: season)
          tournament_round = create(:tournament_round, tournament: player.club.tournament, season: season)
          create(:round_player, player: player, tournament_round: tournament_round, score: 6, in_squad: true)
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

# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'MantraFootball API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3333'
        },
        {
          url: 'https://staging.mantrafootball.org'
        },
        {
          url: 'https://mantrafootball.org'
        }
      ],
      components: {
        schemas: {
          error_not_found: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    key: { type: :string, example: 'not_found' },
                    message: { type: :string, example: 'Resource not found' }
                  },
                  required: %w[key message]
                }
              }
            },
            required: %w[errors]
          },
          league: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              auction_type: { type: :string, example: 'blind_bids', description: 'Available values: blind_bids, live' },
              cloning_status: { type: :string, example: 'unclonable', description: 'Available values: unclonable, cloneable' },
              division: { type: :string, example: 'A1', nullable: true },
              division_id: { type: :integer, example: '123', nullable: true },
              leader: { type: :string, example: 'Rossoneri', nullable: true },
              leader_logo: { type: :string, example: 'https://s3.amazonaws.com/teams/default.png', nullable: true },
              link: { type: :string, example: '/leagues/link' },
              mantra_format: { type: :boolean, example: true, description: 'true for Mantra, false for national and eurocup leagues' },
              max_avg_def_score: { type: :string, example: '8.0' },
              min_avg_def_score: { type: :string, example: '7.0' },
              name: { type: :string, example: 'San Siro' },
              promotion: { type: :integer, example: 2 },
              relegation: { type: :integer, example: 3 },
              round: { type: :integer, example: 13 },
              season_id: { type: :integer, example: 123 },
              season_end_year: { type: :integer, example: 2024 },
              season_start_year: { type: :integer, example: 2023 },
              status: { type: :string, example: :integer, description: 'Available values: initial, active, archived' },
              teams_count: { type: :integer, example: 8 },
              tournament_id: { type: :integer, example: 321 },
              transfer_status: { type: :string, example: 'closed', description: 'Available values: closed, open' }
            },
            required: %w[id name]
          },
          league_base: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              division: { type: :string, example: 'A1', nullable: true },
              division_id: { type: :integer, example: 123, nullable: true },
              link: { type: :string, example: '/leagues/link' },
              name: { type: :string, example: 'San Siro' },
              season_id: { type: :integer, example: 123 },
              status: { type: :string, example: 'active', description: 'Available values: initial, active, archived' },
              tournament_id: { type: :integer, example: 321 }
            },
            required: %w[id name]
          },
          result: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              best_lineup: { type: :string, example: '99.5' },
              draws: { type: :integer, example: 3 },
              form: { type: :array, items: { type: :string, example: 'W' }, example: %w[W D L] },
              goals_difference: { type: :integer, example: 13 },
              history: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    pos: { type: :integer, example: 5, description: 'position' },
                    p: { type: :integer, example: 33, description: 'points' },
                    sg: { type: :integer, example: 33, description: 'scored_goals' },
                    mg: { type: :integer, example: 33, description: 'missed_goals' },
                    w: { type: :integer, example: 33, description: 'wins' },
                    d: { type: :integer, example: 33, description: 'draws' },
                    l: { type: :integer, example: 33, description: 'loses' },
                    ts: { type: :string, example: '599.5', description: 'total_score' }
                  }
                },
                nullable: true
              },
              league_id: { type: :integer, example: 123 },
              loses: { type: :integer, example: 3 },
              matches_played: { type: :integer, example: 9 },
              missed_goals: { type: :integer, example: 19 },
              next_opponent_id: { type: :integer, example: 123, nullable: true, description: 'Team id of next opponent' },
              points: { type: :integer, example: 43 },
              scored_goals: { type: :integer, example: 53 },
              team_id: { type: :integer, example: 153 },
              total_score: { type: :string, example: '899.5' },
              wins: { type: :integer, example: 3 }
            },
            required: %w[id league_id team_id]
          },
          season: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              end_year: { type: :integer, example: 2024 },
              start_year: { type: :integer, example: 2023 }
            },
            required: %w[id end_year start_year]
          },
          team: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              budget: { type: :integer, example: 260 },
              code: { type: :string, example: 'ROS' },
              human_name: { type: :string, example: 'Rossoneri' },
              league_id: { type: :integer, example: 123, nullable: true },
              logo_path: { type: :string, example: '/assets/path/team.png' },
              players: { type: :array, items: { type: :integer, example: 13 }, example: %w[13 4323 954] },
              user_id: { type: :integer, example: 123, nullable: true }
            },
            required: %w[id]
          },
          tournament: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              name: { type: :string, example: 'Italy' },
              icon: { type: :string, example: '🇮🇹', nullable: true },
              logo: { type: :string, example: '/assets/path/italy.png', nullable: true },
              short_name: { type: :string, example: 'Italy', nullable: true }
            },
            required: %w[id name]
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end

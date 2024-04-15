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
          club: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              code: { type: :string, example: 'MIL' },
              color: { type: :string, example: 'DB0A23' },
              kit_path: { type: :string, example: 'https://aws.com/assets/path/kit.png' },
              logo_path: { type: :string, example: 'https://aws.com/assets/path/logo.png' },
              name: { type: :string, example: 'Milan' },
              profile_kit_path: { type: :string, example: 'https://aws.com/assets/path/kit.png' },
              status: { type: :string, example: 'active', description: 'Available values: active, archived' },
              tm_url: { type: :string, example: 'https://www.transfermarkt.com/ac-mailand/startseite/verein/5', nullable: true },
              tournament_id: { type: :integer, example: 321 }
            },
            required: %w[id code name]
          },
          current_season_stats: {
            type: :object,
            properties: {
              assists: { type: :integer, example: 5 },
              base_score: { type: :float, example: 7.42 },
              caught_penalty: { type: :integer, example: 5 },
              cleansheet: { type: :integer, example: 5 },
              conceded_penalty: { type: :integer, example: 5 },
              failed_penalty: { type: :integer, example: 5 },
              goals: { type: :integer, example: 5 },
              missed_goals: { type: :integer, example: 5 },
              missed_penalty: { type: :integer, example: 5 },
              own_goals: { type: :integer, example: 5 },
              penalties_won: { type: :integer, example: 5 },
              played_matches: { type: :integer, example: 25 },
              played_minutes: { type: :integer, example: 777 },
              red_card: { type: :integer, example: 5 },
              saves: { type: :integer, example: 5 },
              scored_penalty: { type: :integer, example: 5 },
              total_score: { type: :float, example: 8.99 },
              yellow_card: { type: :integer, example: 5 }
            }
          },
          division: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              level: { type: :string, example: 'A' },
              leagues: { type: :array, items: { '$ref' => '#/components/schemas/league_base' } }
            },
            required: %w[id level]
          },
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
          national_team: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              code: { type: :string, example: 'it' },
              color: { type: :string, example: 'DB0A23' },
              kit_path: { type: :string, example: 'https://aws.com/assets/path/kit.png' },
              name: { type: :string, example: 'Italy' },
              profile_kit_path: { type: :string, example: 'https://aws.com/assets/path/kit.png' },
              status: { type: :string, example: 'active', description: 'Available values: active, archived' },
              tournament_id: { type: :integer, example: 321 }
            },
            required: %w[id code name]
          },
          player: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              appearances: { type: :integer, example: 123 },
              avatar_path: { type: :string, example: 'https://aws.com/assets/path/kit.png' },
              average_base_score: { type: :float, example: 7.65 },
              average_price: { type: :float, example: 33.3 },
              average_total_score: { type: :float, example: 7.89 },
              club: { '$ref' => '#/components/schemas/club' },
              first_name: { type: :string, example: 'David', nullable: true },
              league_price: { type: :integer, example: 25, nullable: true },
              league_team_logo: { type: :string, example: 'https://aws.com/assets/path/team.png', nullable: true },
              name: { type: :string, example: 'Beckham' },
              position_classic_arr: { type: :array, items: { type: :string, example: 'RB' }, example: %w[RB WB] },
              position_ital_arr: { type: :array, items: { type: :string, example: 'Dd' }, example: %w[Dd E] },
              teams_count: { type: :integer, example: 13 },
              age: { type: :integer, example: 33, nullable: true },
              birth_date: { type: :string, example: 'Apr 17, 1996' },
              country: { type: :string, example: 'Italy', nullable: true },
              height: { type: :integer, example: 189, nullable: true },
              leagues: { type: :array, items: { type: :integer, example: 44 }, example: [44, 55] },
              national_team: { '$ref' => '#/components/schemas/national_team', nullable: true },
              number: { type: :integer, example: 189, nullable: true },
              profile_avatar_path: { type: :string, example: 'https://aws.com/assets/path/kit.png' },
              stats_price: { type: :integer, example: 15 },
              team_ids: { type: :array, items: { type: :integer, example: 444 }, example: [444, 555] },
              tm_price: { type: :integer, example: 1_000_000, nullable: true },
              tm_url: { type: :string, example: 'https://www.transfermarkt.com/profil/spieler/123', nullable: true }
            },
            required: %w[id name]
          },
          player_season_stat: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              assists: { type: :integer, example: 5 },
              base_score: { type: :float, example: 7.42 },
              caught_penalty: { type: :integer, example: 5 },
              cleansheet: { type: :integer, example: 5 },
              club_id: { type: :integer, example: 123 },
              conceded_penalty: { type: :integer, example: 5 },
              failed_penalty: { type: :integer, example: 5 },
              goals: { type: :integer, example: 5 },
              missed_goals: { type: :integer, example: 5 },
              missed_penalty: { type: :integer, example: 5 },
              own_goals: { type: :integer, example: 5 },
              penalties_won: { type: :integer, example: 5 },
              played_matches: { type: :integer, example: 25 },
              played_minutes: { type: :integer, example: 777 },
              player_id: { type: :integer, example: 123 },
              position_price: { type: :integer, example: 15 },
              position_classic_arr: { type: :array, items: { type: :string, example: 'RB' }, example: %w[RB WB] },
              position_ital_arr: { type: :array, items: { type: :string, example: 'Dd' }, example: %w[Dd E] },
              red_card: { type: :integer, example: 5 },
              saves: { type: :integer, example: 5 },
              scored_penalty: { type: :integer, example: 5 },
              season_id: { type: :integer, example: 123 },
              total_score: { type: :float, example: 8.99 },
              tournament_id: { type: :integer, example: 123 },
              yellow_card: { type: :integer, example: 5 }
            },
            required: %w[id]
          },
          player_stats: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              current_season_stat: { '$ref' => '#/components/schemas/current_season_stats' },
              current_season_stat_eurocup: { '$ref' => '#/components/schemas/current_season_stats' },
              current_season_stat_national: { '$ref' => '#/components/schemas/current_season_stats' },
              round_stats: { type: :array, items: { '$ref' => '#/components/schemas/round_stats' } },
              round_stats_eurocup: { type: :array, items: { '$ref' => '#/components/schemas/round_stats' } },
              round_stats_national: { type: :array, items: { '$ref' => '#/components/schemas/round_stats' } },
              season_stats: { type: :array, items: { '$ref' => '#/components/schemas/player_season_stat' } }
            },
            required: %w[id]
          },
          player_base: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              appearances: { type: :integer, example: 123 },
              avatar_path: { type: :string, example: 'https://aws.com/assets/path/kit.png' },
              average_base_score: { type: :float, example: 7.65 },
              average_price: { type: :float, example: 33.3 },
              average_total_score: { type: :float, example: 7.89 },
              club: { '$ref' => '#/components/schemas/club' },
              first_name: { type: :string, example: 'David', nullable: true },
              league_price: { type: :integer, example: 25, nullable: true },
              league_team_logo: { type: :string, example: 'https://aws.com/assets/path/team.png', nullable: true },
              name: { type: :string, example: 'Beckham' },
              position_classic_arr: { type: :array, items: { type: :string, example: 'RB' }, example: %w[RB WB] },
              position_ital_arr: { type: :array, items: { type: :string, example: 'Dd' }, example: %w[Dd E] },
              teams_count: { type: :integer, example: 13 }
            },
            required: %w[id name]
          },
          result: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              best_lineup: { type: :string, example: '99.5' },
              draws: { type: :integer, example: 3 },
              form: { type: :array, items: { type: :string, example: 'W' }, example: %w[W D L], nullable: true },
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
              team: { '$ref' => '#/components/schemas/team' },
              total_score: { type: :string, example: '899.5' },
              wins: { type: :integer, example: 3 }
            },
            required: %w[id league_id team]
          },
          round_stats: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              assists: { type: :float, example: 1.0 },
              base_score: { type: :float, example: 7.42 },
              caught_penalty: { type: :float, example: 1.0 },
              cleansheet: { type: :float, example: 1.0 },
              club_id: { type: :integer, example: 5, nullable: true },
              conceded_penalty: { type: :integer, example: 5 },
              failed_penalty: { type: :float, example: 1.0 },
              goals: { type: :float, example: 1.0 },
              missed_goals: { type: :float, example: 1.0 },
              missed_penalty: { type: :float, example: 1.0 },
              own_goals: { type: :float, example: 1.0 },
              penalties_won: { type: :integer, example: 5 },
              played_minutes: { type: :integer, example: 777 },
              player_id: { type: :integer, example: 123 },
              red_card: { type: :float, example: 2.0 },
              saves: { type: :integer, example: 5 },
              scored_penalty: { type: :float, example: 1.0 },
              total_score: { type: :float, example: 8.99 },
              tournament_round_id: { type: :integer, example: 5 },
              tournament_round_number: { type: :integer, example: 5 },
              yellow_card: { type: :float, example: 1.0 }
            }
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
              logo_path: { type: :string, example: 'https://aws.com/assets/path/team.png' },
              players: { type: :array, items: { type: :integer, example: 13 }, example: %w[13 4323 954] },
              user_id: { type: :integer, example: 123, nullable: true }
            },
            required: %w[id]
          },
          tournament: {
            type: :object,
            properties: {
              id: { type: :integer, example: 123 },
              icon: { type: :string, example: '🇮🇹', nullable: true },
              logo: { type: :string, example: '/assets/path/italy.png', nullable: true },
              mantra_format: { type: :boolean, example: true, description: 'true for Mantra, false for national and eurocup leagues' },
              name: { type: :string, example: 'Italy' },
              short_name: { type: :string, example: 'Italy', nullable: true },
              clubs: { type: :array, items: { '$ref' => '#/components/schemas/club' }, nullable: true }
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

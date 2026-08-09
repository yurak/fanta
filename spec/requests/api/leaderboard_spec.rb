require 'swagger_helper'

RSpec.describe 'Leaderboard' do
  def manager_with(wins:, loses: 0)
    league = create(:archived_league)
    user = create(:user)
    team = create(:team, user: user, league: league)
    create(:result, team: team, league: league, wins: wins, loses: loses)
    user
  end

  path '/api/leaderboard' do
    get('managers leaderboard') do
      tags 'Leaderboard'
      produces 'application/json'
      parameter name: :metric, in: :query, required: false,
                schema: { type: :string, enum: %w[win_rate avg_total_score titles matches] }
      parameter name: :tournament_id, in: :query, required: false, schema: { type: :integer }
      parameter name: :include_newbies, in: :query, required: false, schema: { type: :boolean }
      parameter name: :min_matches, in: :query, required: false, schema: { type: :integer }

      let(:metric) { 'win_rate' }
      let(:tournament_id) { nil }
      let(:include_newbies) { nil }
      let(:min_matches) { nil }
      let!(:leader) { manager_with(wins: 9, loses: 1) }
      let!(:runner_up) { manager_with(wins: 5, loses: 5) }

      response 200, 'Success' do
        schema type: :object,
               properties: {
                 data: { type: :array, items: { '$ref' => '#/components/schemas/leaderboard_entry' } },
                 meta: {
                   type: :object,
                   properties: {
                     size: { type: :integer },
                     page: { type: :object },
                     current_user: { '$ref' => '#/components/schemas/leaderboard_entry', nullable: true }
                   }
                 }
               }

        run_test! do |response|
          data = JSON.parse(response.body)['data']

          aggregate_failures do
            expect(data.pluck('id')).to eq([leader.id, runner_up.id])
            expect(data.first).to include('rank' => 1, 'value' => 90.0, 'name' => leader.name)
          end
        end
      end
    end
  end

  describe 'current user meta' do
    let!(:runner_up) { manager_with(wins: 5, loses: 5) }

    before do
      manager_with(wins: 9, loses: 1)
      sign_in runner_up
      get '/api/leaderboard', params: { metric: 'win_rate' }
    end

    it 'returns the current user entry with its rank' do
      expect(response.parsed_body['meta']['current_user']).to include('id' => runner_up.id, 'rank' => 2)
    end
  end
end

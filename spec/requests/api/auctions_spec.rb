require 'swagger_helper'

RSpec.describe 'Api::Auctions' do
  row_schema = {
    type: :object,
    properties: {
      href: { type: :string },
      icon: { type: :string },
      icon_active: { type: :boolean },
      title: { type: :string },
      title_status: { type: :string, nullable: true },
      item_status: { type: :string },
      transfers: { type: :string },
      transfers_status: { type: :string, nullable: true },
      status: { type: :string },
      status_text: { type: :string },
      status_icon: { type: :string },
      date: { type: :string, nullable: true },
      arrow_icon: { type: :string }
    }
  }

  path '/api/leagues/{league_id}/auctions' do
    parameter name: 'league_id', in: :path, type: :string, description: 'League id'

    get('list league auctions with their rows (main + dropping)') do
      tags 'Auctions'
      produces 'application/json'

      response 200, 'Success' do
        let(:league) { create(:league) }
        let(:league_id) { league.id }

        before do # rubocop:disable RSpec/ScatteredSetup
          create(:auction, league: league, status: :sales, number: 2)
          sign_in create(:user)
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     auctions: {
                       type: :array,
                       items: {
                         type: :object,
                         properties: {
                           hidden: { type: :boolean },
                           rows: { type: :array, items: row_schema }
                         }
                       }
                     }
                   }
                 }
               }

        run_test! do |response|
          auctions = JSON.parse(response.body).dig('data', 'auctions')
          aggregate_failures do
            expect(auctions.size).to eq(1)
            expect(auctions.first['rows'].first).to include('href', 'title', 'status', 'status_icon')
          end
        end
      end

      response 404, 'League not found' do
        let(:league_id) { 'invalid' }

        before { sign_in create(:user) } # rubocop:disable RSpec/ScatteredSetup

        schema '$ref' => '#/components/schemas/error_not_found'

        run_test!
      end
    end
  end
end

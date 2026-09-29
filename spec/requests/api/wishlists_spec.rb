require 'swagger_helper'

# rswag builds every `response` block as its own example group, but the cop reads them as one
# and calls their separate setups scattered.
# rubocop:disable RSpec/ScatteredSetup
RSpec.describe 'Api::Wishlists' do
  wishlist_schema = {
    type: :object,
    properties: {
      id: { type: :integer },
      shared: { type: :boolean },
      players_count: { type: :integer },
      max_players: { type: :integer },
      editable: { type: :boolean },
      owner: { type: :object, properties: { id: { type: :integer }, name: { type: :string } } },
      tournament: { type: :object },
      season: { type: :object }
    }
  }

  path '/api/wishlists' do
    get('the signed-in user wishlists for the current season') do
      tags 'Wishlists'
      produces 'application/json'

      response 200, 'Success' do
        let(:user) { create(:user) }
        let!(:season) { Season.last || create(:season) }

        before do
          create(:wishlist, user: user, season: season)
          create(:wishlist, user: create(:user), season: season) # someone else
          sign_in user
        end

        schema type: :object, properties: { data: { type: :array, items: wishlist_schema } }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data'].size).to eq(1)
        end
      end

      response 401, 'Unauthorized', document: false do
        run_test!
      end
    end
  end

  path '/api/wishlists/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'Wishlist id'

    get('one wishlist') do
      tags 'Wishlists'
      produces 'application/json'

      response 200, 'Success — the owner reads his own private list' do
        let(:wishlist) { create(:wishlist) }
        let(:id) { wishlist.id }

        before { sign_in wishlist.user }

        schema type: :object, properties: { data: wishlist_schema }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['editable']).to be(true)
          expect(body['data']['season']['id']).to eq(wishlist.season_id)
        end
      end

      # The address is public, so a stranger is told the list is private rather than shown it.
      response 403, 'A private list of someone else' do
        let(:wishlist) { create(:wishlist) }
        let(:id) { wishlist.id }

        before { sign_in create(:user) }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['errors'].first['key']).to eq('wishlist_private')
        end
      end

      response 403, 'A private list opened by a guest', document: false do
        let(:wishlist) { create(:wishlist) }
        let(:id) { wishlist.id }

        run_test!
      end

      response 200, 'A shared list read by a guest', document: false do
        let(:wishlist) { create(:wishlist, :shared) }
        let(:id) { wishlist.id }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['editable']).to be(false)
        end
      end

      response 404, 'Unknown list', document: false do
        let(:id) { 0 }

        before { sign_in create(:user) }

        run_test!
      end
    end

    patch('open the list to everyone, or close it again') do
      tags 'Wishlists'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object, properties: { shared: { type: :boolean } }, required: %w[shared]
      }

      response 200, 'Success' do
        let(:wishlist) { create(:wishlist) }
        let(:id) { wishlist.id }
        let(:payload) { { shared: true } }

        before { sign_in wishlist.user }

        schema type: :object, properties: { data: wishlist_schema }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['shared']).to be(true)
          expect(wishlist.reload.shared).to be(true)
        end
      end

      response 403, 'Someone else list' do
        let(:wishlist) { create(:wishlist) }
        let(:id) { wishlist.id }
        let(:payload) { { shared: true } }

        before { sign_in create(:user) }

        run_test! do |_response|
          expect(wishlist.reload.shared).to be(false)
        end
      end
    end
  end
end
# rubocop:enable RSpec/ScatteredSetup

require 'swagger_helper'

RSpec.describe 'Api::WishlistPlayers' do
  path '/api/wishlist_players' do
    post('put a player on the wishlist of his own competition') do
      tags 'Wishlists'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object, properties: { player_id: { type: :integer } }, required: %w[player_id]
      }

      response 200, 'Success' do
        let!(:season) { Season.last || create(:season) }
        let(:user) { create(:user) }
        let(:tournament) { create(:tournament) }
        let(:player) { create(:player, club: create(:club, tournament: tournament)) }
        let(:payload) { { player_id: player.id } }

        before { sign_in user }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     player_id: { type: :integer },
                     wishlisted: { type: :boolean },
                     wishlist: { type: :object }
                   }
                 }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['wishlisted']).to be(true)
          expect(user.wishlists.last.players).to contain_exactly(player)
        end
      end

      # Clicking twice against a stale page must not raise or double the row.
      response 200, 'Already on the list', document: false do
        let!(:season) { Season.last || create(:season) }
        let(:user) { create(:user) }
        let(:player) { create(:player, club: create(:club, tournament: create(:tournament))) }
        let(:payload) { { player_id: player.id } }

        before do
          sign_in user
          Wishlists::PlayerUpdater.call(user: user, player: player, wanted: true)
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['wishlisted']).to be(true)
          expect(WishlistPlayer.count).to eq(1)
        end
      end

      response 403, 'A player of a fanta competition' do
        let!(:season) { Season.last || create(:season) }
        let(:player) { create(:player, club: create(:club, tournament: create(:fanta_tournament))) }
        let(:payload) { { player_id: player.id } }

        before { sign_in create(:user) }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['errors'].first['key']).to eq('wishlist_not_allowed')
        end
      end

      response 422, 'The list is full' do
        let!(:season) { Season.last || create(:season) }
        let(:user) { create(:user) }
        let(:tournament) { create(:tournament) }
        let(:player) { create(:player, club: create(:club, tournament: tournament)) }
        let(:payload) { { player_id: player.id } }

        before do
          sign_in user
          wishlist = Wishlist.fetch_or_create(user: user, tournament: tournament, season: season)
          allow(Wishlist).to receive(:fetch_or_create).and_return(wishlist)
          allow(wishlist).to receive(:full?).and_return(true)
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['errors'].first['key']).to eq('wishlist_full')
        end
      end

      response 404, 'Unknown player', document: false do
        let(:payload) { { player_id: 0 } }

        before { sign_in create(:user) }

        run_test!
      end

      response 401, 'Unauthorized', document: false do
        let(:payload) { { player_id: create(:player).id } }

        run_test!
      end
    end
  end

  path '/api/wishlist_players/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'Player id'

    delete('take a player off the wishlist') do
      tags 'Wishlists'
      produces 'application/json'

      response 200, 'Success' do
        let!(:season) { Season.last || create(:season) }
        let(:user) { create(:user) }
        let(:player) { create(:player, club: create(:club, tournament: create(:tournament))) }
        let(:id) { player.id }

        before do
          sign_in user
          Wishlists::PlayerUpdater.call(user: user, player: player, wanted: true)
        end

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['wishlisted']).to be(false)
          expect(WishlistPlayer.count).to eq(0)
        end
      end

      response 200, 'He was not on the list anyway', document: false do
        let!(:season) { Season.last || create(:season) }
        let(:player) { create(:player, club: create(:club, tournament: create(:tournament))) }
        let(:id) { player.id }

        before { sign_in create(:user) }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body['data']['wishlisted']).to be(false)
        end
      end
    end
  end
end

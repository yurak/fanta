RSpec.describe 'AuctionRounds' do
  let(:auction_round) { create(:auction_round) }

  describe 'GET #show' do
    context 'when user is logged out' do
      before do
        get auction_round_path(auction_round)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in and has auction bid' do
      let(:logged_user) { create(:user) }
      let(:team) { create(team, user: logged_user, league: auction_round.league) }
      let(:auction_bid) { create(:auction_bid, team: team, auction_round: auction_round) }

      before do
        sign_in logged_user

        get auction_round_path(auction_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:transfers)).not_to be_nil }
    end

    context 'when the manager has a wishlist for this competition' do
      let(:logged_user) { create(:user) }
      let(:league) { auction_round.league }
      let(:wishlist) do
        create(:wishlist, user: logged_user, tournament: league.tournament, season: league.season)
      end

      before do
        team = create(:team, user: logged_user, league: league)
        create(:auction_bid, :with_empty_player_bids, team: team, auction_round: auction_round)
        sign_in logged_user
      end

      it 'offers the wishlist filter in the player slot' do
        create(:wishlist_player, wishlist: wishlist, player: create(:player))

        get auction_round_path(auction_round)

        expect(response.body).to include('search-wishlist-chip')
      end

      it 'leaves the filter out while nobody is on the list' do
        wishlist

        get auction_round_path(auction_round)

        expect(response.body).not_to include('search-wishlist-chip')
      end
    end

    context 'with invalid auction round id' do
      login_user
      before do
        get auction_round_path('tour_random_id')
      end

      it { expect(response).not_to be_successful }
      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
      it { expect(assigns(:transfers)).to be_nil }
    end
  end
end

RSpec.describe 'PlayerBids' do
  describe 'PUT/PATCH #update' do
    let(:player_bid) { create(:player_bid) }
    let(:player) { create(:player) }

    let(:params) do
      {
        player_id: player.id,
        price: '123'
      }
    end

    before do
      put player_bid_path(player_bid, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      login_user
      before do
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not update player id' do
        expect(player_bid.reload.player_id).not_to eq(player.id)
      end

      it 'does not update price' do
        expect(player_bid.reload.price).not_to eq(123)
      end
    end

    context 'without player_bid when user is logged in' do
      login_user
      before do
        put player_bid_path('123456', params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not update player id' do
        expect(player_bid.reload.player_id).not_to eq(player.id)
      end

      it 'does not update price' do
        expect(player_bid.reload.price).not_to eq(123)
      end
    end

    context 'with wrong player id when user is logged in' do
      let(:params) do
        {
          player_id: '5264563567',
          price: '123'
        }
      end

      login_user
      before do
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not update player id' do
        expect(player_bid.reload.player_id).not_to eq(player.id)
      end

      it 'does not update price' do
        expect(player_bid.reload.price).not_to eq(123)
      end
    end

    context 'when auction bid of other team' do
      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: player_bid.auction_bid.auction_round.league)
        sign_in logged_user
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not update player id' do
        expect(player_bid.reload.player_id).not_to eq(player.id)
      end

      it 'does not update price' do
        expect(player_bid.reload.price).not_to eq(123)
      end
    end

    context 'with own team when auction round is processing' do
      let(:auction_round) { create(:processing_auction_round) }
      let(:logged_user) { create(:user) }
      let(:player_bid) do
        auction_bid = create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league),
                                           auction_round: auction_round)
        create(:player_bid, auction_bid: auction_bid)
      end

      before do
        sign_in logged_user
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not update player id' do
        expect(player_bid.reload.player_id).not_to eq(player.id)
      end

      it 'does not update price' do
        expect(player_bid.reload.price).not_to eq(123)
      end
    end

    context 'with own team when auction round is closed' do
      let(:auction_round) { create(:closed_auction_round) }
      let(:logged_user) { create(:user) }
      let(:player_bid) do
        auction_bid = create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league),
                                           auction_round: auction_round)
        create(:player_bid, auction_bid: auction_bid)
      end

      before do
        sign_in logged_user
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not update player id' do
        expect(player_bid.reload.player_id).not_to eq(player.id)
      end

      it 'does not update price' do
        expect(player_bid.reload.price).not_to eq(123)
      end
    end

    context 'with own team and dumped player' do
      let(:auction_round) { create(:auction_round) }
      let(:logged_user) { create(:user) }
      let(:player_bid) do
        auction_bid = create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league),
                                           auction_round: auction_round)
        create(:player_bid, auction_bid: auction_bid)
      end

      before do
        create(:transfer, status: 'outgoing', auction: auction_round.auction, league: auction_round.league,
                          team: player_bid.auction_bid.team, player: player)
        sign_in logged_user
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not update player id' do
        expect(player_bid.reload.player_id).not_to eq(player.id)
      end

      it 'does not update price' do
        expect(player_bid.reload.price).not_to eq(123)
      end
    end

    context 'with own team and sold player in league' do
      let(:auction_round) { create(:auction_round) }
      let(:logged_user) { create(:user) }
      let(:player_bid) do
        auction_bid = create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league),
                                           auction_round: auction_round)
        create(:player_bid, auction_bid: auction_bid)
      end

      before do
        create(:player_team, player: player, team: create(:team, league: auction_round.league))
        sign_in logged_user
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not update player id' do
        expect(player_bid.reload.player_id).not_to eq(player.id)
      end

      it 'does not update price' do
        expect(player_bid.reload.price).not_to eq(123)
      end
    end

    context 'with own team and initial auction bid' do
      let(:auction_round) { create(:auction_round) }
      let(:logged_user) { create(:user) }
      let(:player_bid) do
        auction_bid = create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league),
                                           auction_round: auction_round)
        create(:player_bid, auction_bid: auction_bid)
      end

      before do
        sign_in logged_user
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates player id' do
        expect(player_bid.reload.player_id).to eq(player.id)
      end

      it 'updates price' do
        expect(player_bid.reload.price).to eq(123)
      end
    end

    context 'with own team and ongoing auction bid' do
      let(:auction_round) { create(:auction_round) }
      let(:logged_user) { create(:user) }
      let(:player_bid) do
        auction_bid = create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league),
                                           auction_round: auction_round, status: 'ongoing')
        create(:player_bid, auction_bid: auction_bid)
      end

      before do
        sign_in logged_user
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates player id' do
        expect(player_bid.reload.player_id).to eq(player.id)
      end

      it 'updates price' do
        expect(player_bid.reload.price).to eq(123)
      end
    end

    context 'with own team and submitted auction bid' do
      let(:auction_round) { create(:auction_round) }
      let(:logged_user) { create(:user) }
      let(:player_bid) do
        auction_bid = create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league),
                                           auction_round: auction_round, status: 'submitted')
        create(:player_bid, auction_bid: auction_bid)
      end

      before do
        sign_in logged_user
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates player id' do
        expect(player_bid.reload.player_id).to eq(player.id)
      end

      it 'updates price' do
        expect(player_bid.reload.price).to eq(123)
      end
    end

    context 'with own team and completed auction bid' do
      let(:auction_round) { create(:auction_round) }
      let(:logged_user) { create(:user) }
      let(:player_bid) do
        auction_bid = create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league),
                                           auction_round: auction_round, status: 'completed')
        create(:player_bid, auction_bid: auction_bid)
      end

      before do
        sign_in logged_user
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not update player id' do
        expect(player_bid.reload.player_id).not_to eq(player.id)
      end

      it 'does not update price' do
        expect(player_bid.reload.price).not_to eq(123)
      end
    end

    context 'with own team and processed auction bid' do
      let(:auction_round) { create(:auction_round) }
      let(:logged_user) { create(:user) }
      let(:player_bid) do
        auction_bid = create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league),
                                           auction_round: auction_round, status: 'processed')
        create(:player_bid, auction_bid: auction_bid)
      end

      before do
        sign_in logged_user
        put player_bid_path(player_bid, params)
      end

      it 'return success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'does not update player id' do
        expect(player_bid.reload.player_id).not_to eq(player.id)
      end

      it 'does not update price' do
        expect(player_bid.reload.price).not_to eq(123)
      end
    end
  end
end

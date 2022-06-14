RSpec.describe 'AuctionBids', type: :request do
  describe 'GET #new' do
    let(:auction_round) { create(:auction_round) }

    before do
      get new_auction_round_auction_bid_path(auction_round)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      login_user
      before do
        get new_auction_round_auction_bid_path(auction_round)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction bid already exist' do
      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user, league: auction_round.league)
        sign_in logged_user
        create(:auction_bid, team: team, auction_round: auction_round)
        get new_auction_round_auction_bid_path(auction_round)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team without vacancies' do
      before do
        logged_user = create(:user)
        create(:team, :with_25_players, user: logged_user, league: auction_round.league)
        sign_in logged_user
        get new_auction_round_auction_bid_path(auction_round)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction round is processing' do
      let(:auction_round) { create(:processing_auction_round) }

      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: auction_round.league)
        sign_in logged_user
        get new_auction_round_auction_bid_path(auction_round)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction round is closed' do
      let(:auction_round) { create(:closed_auction_round) }

      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: auction_round.league)
        sign_in logged_user
        get new_auction_round_auction_bid_path(auction_round)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team' do
      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: auction_round.league)
        sign_in logged_user
        get new_auction_round_auction_bid_path(auction_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:auction_bid)).not_to be_nil }
    end
  end

  describe 'POST #create' do
    let(:player_bids_attributes) { nil }
    let(:auction_round) { create(:auction_round) }
    let(:params) do
      {
        auction_bid: {
          player_bids_attributes: player_bids_attributes
        }
      }
    end

    before do
      post auction_round_auction_bids_path(auction_round, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      login_user
      before do
        post auction_round_auction_bids_path(auction_round, params)
      end

      it { expect(response).to redirect_to(new_auction_round_auction_bid_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction bid already exist' do
      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user, league: auction_round.league)
        sign_in logged_user
        create(:auction_bid, team: team, auction_round: auction_round)
        post auction_round_auction_bids_path(auction_round, params)
      end

      it { expect(response).to redirect_to(new_auction_round_auction_bid_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction round is processing' do
      let(:auction_round) { create(:processing_auction_round) }

      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: auction_round.league)
        sign_in logged_user
        post auction_round_auction_bids_path(auction_round, params)
      end

      it { expect(response).to redirect_to(new_auction_round_auction_bid_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction round is closed' do
      let(:auction_round) { create(:closed_auction_round) }

      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: auction_round.league)
        sign_in logged_user
        post auction_round_auction_bids_path(auction_round, params)
      end

      it { expect(response).to redirect_to(new_auction_round_auction_bid_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and duplicate players' do
      let(:player) { create(:player) }
      let(:player_bids_attributes) do
        {
          '0' => { player_id: player.id, price: '13' },
          '1' => { player_id: create(:player).id, price: '5' },
          '2' => { player_id: player.id, price: '8' }
        }
      end

      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: auction_round.league)
        sign_in logged_user
        post auction_round_auction_bids_path(auction_round, params)
      end

      it { expect(response).to redirect_to(new_auction_round_auction_bid_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and when player bids count less than vacancies' do
      let(:player_bids_attributes) do
        {
          '0' => { player_id: create(:player).id, price: '13' },
          '1' => { player_id: create(:player).id, price: '5' },
          '2' => { player_id: create(:player).id, price: '8' }
        }
      end

      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: auction_round.league)
        sign_in logged_user
        post auction_round_auction_bids_path(auction_round, params)
      end

      it { expect(response).to redirect_to(new_auction_round_auction_bid_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and bid price exceeds budget' do
      let(:player_bids_attributes) do
        {
          '0' => { player_id: create(:player).id, price: '13' },
          '1' => { player_id: create(:player).id, price: '10' },
          '2' => { player_id: create(:player).id, price: '10' },
          '3' => { player_id: create(:player).id, price: '10' },
          '4' => { player_id: create(:player).id, price: '10' }
        }
      end

      before do
        logged_user = create(:user)
        create(:team, :with_20_players, budget: 50, user: logged_user, league: auction_round.league)
        sign_in logged_user
        post auction_round_auction_bids_path(auction_round, params)
      end

      it { expect(response).to redirect_to(new_auction_round_auction_bid_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and bid and team contain less than 2 GKs' do
      let(:player_bids_attributes) do
        {
          '0' => { player_id: create(:player).id, price: '5' },
          '1' => { player_id: create(:player).id, price: '6' },
          '2' => { player_id: create(:player).id, price: '7' },
          '3' => { player_id: create(:player).id, price: '8' },
          '4' => { player_id: create(:player).id, price: '10' }
        }
      end

      before do
        logged_user = create(:user)
        create(:team, :with_20_players, budget: 50, user: logged_user, league: auction_round.league)
        sign_in logged_user
        post auction_round_auction_bids_path(auction_round, params)
      end

      it { expect(response).to redirect_to(new_auction_round_auction_bid_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and valid bid' do
      let(:player_bids_attributes) do
        {
          '0' => { player_id: create(:player).id, price: '5' },
          '1' => { player_id: create(:player).id, price: '6' },
          '2' => { player_id: create(:player).id, price: '7' },
          '3' => { player_id: create(:player, :with_pos_por).id, price: '8' },
          '4' => { player_id: create(:player, :with_pos_por).id, price: '10' }
        }
      end

      before do
        logged_user = create(:user)
        create(:team, :with_20_players, budget: 50, user: logged_user, league: auction_round.league)
        sign_in logged_user
        post auction_round_auction_bids_path(auction_round, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'creates auction bid' do
        expect(AuctionBid.count).to eq(1)
      end

      it 'creates player bids' do
        expect(PlayerBid.count).to eq(5)
      end
    end
  end

  describe 'GET #edit' do
    let(:auction_bid) { create(:auction_bid) }
    let(:auction_round) { auction_bid.auction_round }

    before do
      get edit_auction_round_auction_bid_path(auction_round, auction_bid)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      login_user
      before do
        get edit_auction_round_auction_bid_path(auction_round, auction_bid)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when auction bid of other team' do
      before do
        logged_user = create(:user)
        create(:team, :with_25_players, user: logged_user, league: auction_round.league)
        sign_in logged_user
        get edit_auction_round_auction_bid_path(auction_round, auction_bid)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction round is processing' do
      let(:auction_round) { create(:processing_auction_round) }

      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user, league: auction_round.league)
        auction_bid = create(:auction_bid, team: team, auction_round: auction_round)
        sign_in logged_user
        get edit_auction_round_auction_bid_path(auction_round, auction_bid)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction round is closed' do
      let(:auction_round) { create(:closed_auction_round) }

      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user, league: auction_round.league)
        auction_bid = create(:auction_bid, team: team, auction_round: auction_round)
        sign_in logged_user
        get edit_auction_round_auction_bid_path(auction_round, auction_bid)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and valid params' do
      let(:auction_round) { create(:auction_round) }

      before do
        logged_user = create(:user)
        team = create(:team, user: logged_user, league: auction_round.league)
        auction_bid = create(:auction_bid, team: team, auction_round: auction_round)
        sign_in logged_user
        get edit_auction_round_auction_bid_path(auction_round, auction_bid)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:auction_bid)).not_to be_nil }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:auction_bid) { create(:auction_bid) }
    let(:player_bids_attributes) { nil }

    let(:params) do
      {
        auction_bid: {
          player_bids_attributes: player_bids_attributes
        }
      }
    end

    before do
      put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with foreign team when user is logged in' do
      login_user
      before do
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(edit_auction_round_auction_bid_path(auction_bid.auction_round, auction_bid)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when auction bid of other team' do
      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: auction_bid.auction_round.league)
        sign_in logged_user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(edit_auction_round_auction_bid_path(auction_bid.auction_round, auction_bid)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction round is processing' do
      let(:auction_round) { create(:processing_auction_round) }
      let(:logged_user) { create(:user) }
      let(:auction_bid) do
        create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league), auction_round: auction_round)
      end

      before do
        sign_in logged_user
        put auction_round_auction_bid_path(auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(edit_auction_round_auction_bid_path(auction_round, auction_bid)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team when auction round is closed' do
      let(:auction_round) { create(:closed_auction_round) }
      let(:logged_user) { create(:user) }
      let(:auction_bid) do
        create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league), auction_round: auction_round)
      end

      before do
        sign_in logged_user
        put auction_round_auction_bid_path(auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(edit_auction_round_auction_bid_path(auction_round, auction_bid)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and duplicate players' do
      let(:player) { create(:player) }
      let(:player_bids_attributes) do
        {
          '0' => { player_id: player.id, price: '13' },
          '1' => { player_id: create(:player).id, price: '5' },
          '2' => { player_id: player.id, price: '8' }
        }
      end
      let(:team) { create(:team, :with_user) }
      let(:auction_bid) do
        create(:auction_bid, team: team, auction_round: create(:auction_round, auction: create(:auction, league: team.league)))
      end

      before do
        sign_in team.user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(edit_auction_round_auction_bid_path(auction_bid.auction_round, auction_bid)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and when player bids count less than vacancies' do
      let(:player_bids_attributes) do
        {
          '0' => { player_id: create(:player).id, price: '13' },
          '1' => { player_id: create(:player).id, price: '5' },
          '2' => { player_id: create(:player).id, price: '8' }
        }
      end
      let(:team) { create(:team, :with_user, :with_20_players) }
      let(:auction_bid) do
        create(:auction_bid, team: team, auction_round: create(:auction_round, auction: create(:auction, league: team.league)))
      end

      before do
        sign_in team.user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(edit_auction_round_auction_bid_path(auction_bid.auction_round, auction_bid)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and bid price exceeds budget' do
      let(:player_bids_attributes) do
        {
          '0' => { player_id: create(:player).id, price: '13' },
          '1' => { player_id: create(:player).id, price: '10' },
          '2' => { player_id: create(:player).id, price: '10' },
          '3' => { player_id: create(:player).id, price: '10' },
          '4' => { player_id: create(:player).id, price: '10' }
        }
      end
      let(:team) { create(:team, :with_user, :with_20_players, budget: 50) }
      let(:auction_bid) do
        create(:auction_bid, team: team, auction_round: create(:auction_round, auction: create(:auction, league: team.league)))
      end

      before do
        sign_in team.user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(edit_auction_round_auction_bid_path(auction_bid.auction_round, auction_bid)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and bid and team contain less than 2 GKs' do
      let(:player_bids_attributes) do
        {
          '0' => { player_id: create(:player).id, price: '5' },
          '1' => { player_id: create(:player).id, price: '6' },
          '2' => { player_id: create(:player).id, price: '7' },
          '3' => { player_id: create(:player).id, price: '8' },
          '4' => { player_id: create(:player).id, price: '10' }
        }
      end
      let(:team) { create(:team, :with_user, :with_20_players, budget: 50) }
      let(:auction_bid) do
        create(:auction_bid, team: team, auction_round: create(:auction_round, auction: create(:auction, league: team.league)))
      end

      before do
        sign_in team.user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(edit_auction_round_auction_bid_path(auction_bid.auction_round, auction_bid)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'with own team and valid bid' do
      let(:player_bids_attributes) do
        {
          '0' => { player_id: create(:player).id, price: '5' },
          '1' => { player_id: create(:player).id, price: '6' },
          '2' => { player_id: create(:player).id, price: '7' },
          '3' => { player_id: create(:player, :with_pos_por).id, price: '8' },
          '4' => { player_id: create(:player, :with_pos_por).id, price: '10' }
        }
      end
      let(:team) { create(:team, :with_user, :with_20_players, budget: 50) }
      let(:auction_bid) do
        create(:auction_bid, :with_player_bids, team: team,
                                                auction_round: create(:auction_round, auction: create(:auction, league: team.league)))
      end

      before do
        sign_in team.user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_bid.auction_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates player bids' do
        expect(auction_bid.player_bids.last.price).to eq(10)
      end
    end
  end
end

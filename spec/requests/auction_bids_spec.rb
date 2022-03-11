RSpec.describe 'AuctionBids', type: :request do
  describe 'GET #new' do
    let(:team) { create(:team, :with_user) }
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
      it { expect(response).to render_template(:_header) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:auction_bid)).not_to be_nil }
    end
  end

  describe 'POST #create' do
    let(:player_bids_attributes) { nil }
    # let(:player_bids_attributes) do
    #   {"0"=>{"player_id"=>"3476", "price"=>"5"},
    #     "1"=>{"player_id"=>"3372", "price"=>"4"},
    #     "2"=>{"player_id"=>"3446", "price"=>"3"},
    #     "3"=>{"player_id"=>"3555", "price"=>"2"},
    #     "4"=>{"player_id"=>"3544", "price"=>"1"}}
    # end
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

    # TODO: add cases
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

    # TODO: add cases
  end

  describe 'PUT/PATCH #update' do
    let(:auction_bid) { create(:auction_bid) }
    let(:auction_round) { auction_bid.auction_round }
    let(:player_bids_attributes) do
      'TODO'
    end

    let(:params) do
      {
        auction_bid: {
          player_bids_attributes: player_bids_attributes
        }
      }
    end

    before do
      put auction_round_auction_bid_path(auction_round, auction_bid, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    # TODO: add cases
  end
end

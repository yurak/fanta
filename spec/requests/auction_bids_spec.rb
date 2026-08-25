RSpec.describe 'AuctionBids' do
  describe 'GET #show' do
    let(:auction_bid) { create(:auction_bid) }

    context 'when user is logged out' do
      before { get auction_bid_path(auction_bid) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when user is not the bid owner' do
      login_user

      before { get auction_bid_path(auction_bid) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when user is the bid owner without auction_round' do
      let(:logged_user) { create(:user) }
      let(:team) { create(:team, user: logged_user) }
      let(:auction_bid) { create(:auction_bid, team: team, auction_round: nil) }

      before do
        sign_in logged_user
        get auction_bid_path(auction_bid)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(controller.instance_variable_get(:@user_team)).to eq(team) }
      it { expect(controller.instance_variable_get(:@modules)).to eq(TeamModule.all) }
    end

    context 'when user is the bid owner with auction_round' do
      let(:logged_user) { create(:user) }
      let(:auction_round) { create(:auction_round) }
      let(:team) { create(:team, user: logged_user, league: auction_round.league) }
      let(:auction_bid) { create(:auction_bid, team: team, auction_round: auction_round) }

      before do
        sign_in logged_user
        get auction_bid_path(auction_bid)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(controller.instance_variable_get(:@auction_round)).to eq(auction_round) }
      it { expect(controller.instance_variable_get(:@league)).to eq(auction_round.league) }
    end
  end

  describe 'POST #submit' do
    let(:logged_user) { create(:user) }
    let(:team) { create(:team, user: logged_user) }
    let(:auction_bid) { create(:auction_bid, team: team, auction_round: nil) }
    let!(:join) { create(:join, user: logged_user, team: team, tournament: team.tournament, auction_bid: auction_bid) }

    context 'when user is logged out' do
      before { post submit_auction_bid_path(auction_bid) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when user is not the bid owner' do
      login_user

      before { post submit_auction_bid_path(auction_bid) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when user is the bid owner' do
      before do
        sign_in logged_user
        post submit_auction_bid_path(auction_bid)
      end

      it { expect(response).to redirect_to(auction_bid_path(auction_bid)) }
      it { expect(join.reload.status).to eq('pending') }
    end

    context 'when the team also applied in a past season' do
      let(:past_join) do
        create(:join, :approved, user: logged_user, team: team, tournament: team.tournament, season: Season.first)
      end

      before do
        join.update!(season: create(:season, start_year: 2030, end_year: 2031))
        past_join
        sign_in logged_user
        post submit_auction_bid_path(auction_bid)
      end

      it { expect(join.reload.status).to eq('pending') }
      it { expect(past_join.reload.status).to eq('approved') }
    end
  end

  describe 'POST #generate' do
    let(:logged_user) { create(:user) }
    let(:tournament) { create(:tournament) }
    let(:team) { create(:team, user: logged_user) }
    let(:auction_bid) { create(:auction_bid, team: team, auction_round: nil) }

    before do
      create(:season)
      create(:join, user: logged_user, team: team, tournament: tournament, auction_bid: auction_bid)
      11.times { create(:player_bid, auction_bid: auction_bid, player: nil) }
      club = create(:club, tournament: tournament)
      Array.new(12) do |i|
        trait = i.zero? ? :with_pos_por : :with_pos_dc
        player = create(:player, trait, club: club)
        create(:player_season_stat, player: player, club: club, tournament: tournament,
                                    season: Season.second_to_last, played_matches: 20)
      end
    end

    context 'when user is not the bid owner' do
      login_user

      before { post generate_auction_bid_path(auction_bid) }

      it { expect(response).to redirect_to(leagues_path) }
    end

    context 'when user is the bid owner' do
      before do
        sign_in logged_user
        post generate_auction_bid_path(auction_bid)
      end

      it { expect(response).to redirect_to(auction_bid_path(auction_bid)) }

      it 'fills the bid with players' do
        expect(auction_bid.player_bids.where.not(player_id: nil).count).to eq(11)
      end
    end

    context 'when the bid belongs to an auction round (not a join)' do
      let(:auction_bid) { create(:auction_bid, team: team, auction_round: create(:auction_round)) }

      before do
        sign_in logged_user
        post generate_auction_bid_path(auction_bid)
      end

      it 'does not fill the bid' do
        expect(auction_bid.player_bids.where.not(player_id: nil).count).to eq(0)
      end
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

      it { expect(response).to redirect_to(auction_round_path(auction_bid.auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when auction bid of other team' do
      before do
        logged_user = create(:user)
        create(:team, user: logged_user, league: auction_bid.auction_round.league)
        sign_in logged_user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_bid.auction_round)) }
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

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    # The round is still `active` until the cron job processes it, but the deadline already closed it.
    context 'with own team when the first stage deadline has passed' do
      let(:auction_round) { create(:auction_round, number: 1, deadline: 1.minute.ago) }
      let(:logged_user) { create(:user) }
      let(:auction_bid) do
        create(:auction_bid, team: create(:team, user: logged_user, league: auction_round.league), auction_round: auction_round)
      end

      before do
        sign_in logged_user
        put auction_round_auction_bid_path(auction_round, auction_bid, auction_bid: { status: 'submitted' })
      end

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }

      it 'does not confirm the bid' do
        expect(auction_bid.reload.status).not_to eq('submitted')
      end
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

      it { expect(response).to redirect_to(auction_round_path(auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when AuctionBids::Manager returns false' do
      let(:logged_user) { create(:user) }

      before do
        manager = instance_double(AuctionBids::Manager)
        allow(AuctionBids::Manager).to receive(:new).and_return(manager)
        allow(manager).to receive(:call).and_return(false)

        sign_in logged_user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_bid.auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when AuctionBids::Manager returns true' do
      let(:logged_user) { create(:user) }
      let(:auction_bid_params) { params[:auction_bid] }
      let(:params) do
        {
          auction_bid: {
            status: 'ongoing',
            player_bids_attributes: {
              '0': { player_id: '111', price: '128', id: auction_bid.player_bids[0] },
              '1': { player_id: '123', price: '9', id: auction_bid.player_bids[1] },
              '2': { player_id: '321', price: '27', id: auction_bid.player_bids[2] },
              '3': { player_id: '333', price: '15', id: auction_bid.player_bids[3] },
              '4': { player_id: '456', price: '4', id: auction_bid.player_bids[4] }
            }
          }
        }
      end

      before do
        manager = instance_double(AuctionBids::Manager)
        allow(AuctionBids::Manager).to receive(:new).with(auction_bid, auction_bid_params).and_return(manager)
        allow(manager).to receive(:call).and_return(true)

        sign_in logged_user
        put auction_round_auction_bid_path(auction_bid.auction_round, auction_bid, params)
      end

      it { expect(response).to redirect_to(auction_round_path(auction_bid.auction_round)) }
      it { expect(response).to have_http_status(:found) }
    end
  end

  describe 'PUT/PATCH #update without auction_round (join flow)' do
    let(:logged_user) { create(:user) }
    let(:team) { create(:team, user: logged_user) }
    let(:auction_bid) { create(:auction_bid, team: team, auction_round: nil) }
    let(:join) { create(:join, user: logged_user, team: team, tournament: team.tournament, auction_bid: auction_bid) }
    let(:params) { { auction_bid: { status: 'submitted' } } }

    before { join }

    context 'when user is logged out' do
      before { put auction_bid_path(auction_bid, params) }

      it { expect(response).to redirect_to('/users/sign_in') }
    end

    context 'when bid becomes submitted' do
      before do
        sign_in logged_user
        allow(AuctionBids::Manager).to receive(:call)
        auction_bid.update!(status: :submitted)
        put auction_bid_path(auction_bid, params)
      end

      it { expect(response).to redirect_to(join_path(join)) }
      it { expect(join.reload.status).to eq('pending') }
    end

    context 'when bid is not submitted' do
      before do
        sign_in logged_user
        allow(AuctionBids::Manager).to receive(:call)
        put auction_bid_path(auction_bid, params.merge(auction_bid: { status: 'ongoing' }))
      end

      it { expect(response).to redirect_to(auction_bid_path(auction_bid)) }
      it { expect(join.reload.status).to eq('initial') }
    end
  end
end

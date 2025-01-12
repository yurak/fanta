RSpec.describe 'AuctionRounds' do
  let(:auction_round) { create(:auction_round) }

  describe 'GET #show' do
    context 'when user is logged out' do
      before do
        get auction_round_path(auction_round)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:transfers)).not_to be_nil }
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

    context 'with invalid auction round id' do
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

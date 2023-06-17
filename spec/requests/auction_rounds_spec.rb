RSpec.describe 'AuctionRounds' do
  let(:auction_round) { create(:auction_round) }

  describe 'GET #show' do
    before do
      get auction_round_path(auction_round)
    end

    context 'when user is logged out' do
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
  end
end

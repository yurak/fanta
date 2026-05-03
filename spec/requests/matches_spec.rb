RSpec.describe 'Matches' do
  describe 'GET #show' do
    let(:match1) { create(:match) }

    context 'when user is logged out' do
      before do
        get match_path(match1)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get match_path(match1)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
      it { expect(response).to render_template(:_team_squad) }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'with invalid match id' do
      login_user
      before do
        get match_path('invalid_id')
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when tour has no prev or next round' do
      login_user
      before do
        get match_path(match1)
      end

      it { expect(assigns(:prev_tour_match)).to be_nil }
      it { expect(assigns(:next_tour_match)).to be_nil }
    end

    context 'when tour has prev and next rounds with matches' do
      login_user

      let(:league) { create(:league) }
      let(:current_tour) { create(:tour, league: league, number: 2) }
      let(:match1) { create(:match, tour: current_tour) }
      let!(:prev_match) { create(:match, tour: create(:tour, league: league, number: 1)) }
      let!(:next_match) { create(:match, tour: create(:tour, league: league, number: 3)) }

      before do
        get match_path(match1)
      end

      it { expect(assigns(:prev_tour_match)).to eq(prev_match) }
      it { expect(assigns(:next_tour_match)).to eq(next_match) }
    end
  end

  describe 'POST #autobot' do
    let(:match1) { create(:match) }

    context 'when user is logged out' do
      before do
        post match_autobot_path(match1)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        allow_any_instance_of(Match).to receive(:autobot)
        post match_autobot_path(match1)
      end

      it { expect(response).to redirect_to(match_path(match1)) }
      it { expect(response).to have_http_status(:found) }

      it 'calls autobot on the match' do
        call_count = 0
        allow_any_instance_of(Match).to receive(:autobot) { call_count += 1 }
        post match_autobot_path(match1)
        expect(call_count).to eq(1)
      end
    end
  end
end

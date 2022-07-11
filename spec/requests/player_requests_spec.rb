RSpec.describe 'PlayerRequests', type: :request do
  let(:player) { create(:player) }

  describe 'GET #new' do
    before do
      get new_player_player_request_path(player)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get new_player_player_request_path(player)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:player_request)).not_to be_nil }
    end
  end

  describe 'POST #create' do
    let(:logged_user) { create(:user) }
    let(:positions) { %w[Ds Dd E] }
    let(:comment) { 'Text with arguments' }
    let(:params) do
      {
        player_request: {
          user_id: logged_user&.id,
          player_id: player.id,
          positions: positions,
          comment: comment
        }
      }
    end

    before do
      post player_player_requests_path(player, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in and request with valid params' do
      before do
        sign_in logged_user
        post player_player_requests_path(player, params)
      end

      it { expect(response).to redirect_to(player_path(player)) }
      it { expect(response).to have_http_status(:found) }

      it 'creates player_request with specified user' do
        expect(PlayerRequest.last.user).to eq(logged_user)
      end

      it 'creates player_request with specified player' do
        expect(PlayerRequest.last.player).to eq(player)
      end

      it 'creates player_request with specified positions' do
        expect(PlayerRequest.last.positions).to eq(positions.to_s)
      end

      it 'creates player_request with specified comment' do
        expect(PlayerRequest.last.comment).to eq(comment)
      end
    end

    context 'when user is logged in and request with invalid params' do
      let(:positions) { nil }

      before do
        sign_in logged_user
        post player_player_requests_path(player, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:new) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:player_request)).not_to be_nil }
    end
  end
end

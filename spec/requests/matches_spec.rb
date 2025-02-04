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
  end
end

RSpec.describe 'WeeklyTeams' do
  describe 'GET #show' do
    context 'when weekly team exists' do
      let(:weekly_team) { create(:weekly_team) }

      before { get weekly_team_path(weekly_team) }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:show) }
    end

    context 'when weekly team has players' do
      let(:weekly_team) { create(:weekly_team, :with_player) }

      before { get weekly_team_path(weekly_team) }

      it { expect(response).to be_successful }
    end

    context 'when user is logged in' do
      let(:weekly_team) { create(:weekly_team) }

      before do
        sign_in create(:user)
        get weekly_team_path(weekly_team)
      end

      it { expect(response).to be_successful }
    end

    context 'when weekly team does not exist' do
      before { get weekly_team_path(0) }

      it { expect(response).to have_http_status(:not_found) }
    end
  end
end

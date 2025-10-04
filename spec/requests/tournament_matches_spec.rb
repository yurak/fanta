RSpec.describe 'TournamentMatches' do
  let(:tournament_match) { create(:tournament_match) }

  describe 'GET #edit' do
    before do
      get edit_tournament_match_path(tournament_match)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        get edit_tournament_match_path(tournament_match)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        get edit_tournament_match_path(tournament_match)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:tournament_match)).not_to be_nil }
    end

    context 'when admin is logged in' do
      login_admin
      before do
        get edit_tournament_match_path(tournament_match)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:tournament_match)).not_to be_nil }
    end
  end

  describe 'PUT/PATCH #update' do
    let(:params) do
      {
        tournament_match: {
          host_score: 2,
          guest_score: 1,
          time: '21:45'
        }
      }
    end

    before do
      patch tournament_match_path(tournament_match, params)
    end

    context 'when user is logged out' do
      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when user is logged in' do
      login_user
      before do
        patch tournament_match_path(tournament_match, params)
      end

      it { expect(response).to redirect_to(leagues_path) }
      it { expect(response).to have_http_status(:found) }
    end

    context 'when moderator is logged in' do
      login_moderator
      before do
        patch tournament_match_path(tournament_match, params)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_match.tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates tournament_match with specified host_score' do
        expect(tournament_match.reload.host_score).to eq(params[:tournament_match][:host_score])
      end
    end

    context 'when admin is logged in' do
      login_admin
      before do
        patch tournament_match_path(tournament_match, params)
      end

      it { expect(response).to redirect_to(tournament_round_path(tournament_match.tournament_round)) }
      it { expect(response).to have_http_status(:found) }

      it 'updates tournament_match with specified host_score' do
        expect(tournament_match.reload.host_score).to eq(params[:tournament_match][:host_score])
      end
    end
  end
end

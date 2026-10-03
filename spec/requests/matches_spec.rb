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

    context 'when the real match is being played' do
      login_user

      let(:tournament) { create(:tournament) }
      let(:club) { create(:club, tournament: tournament) }
      let(:league) { create(:league, tournament: tournament) }
      let(:tour) { create(:tour, league: league, status: :locked) }
      let(:match1) { create(:match, tour: tour) }

      let(:bench_player) { create(:player, club: club) }
      let(:absent_player) { create(:player, club: club) }

      before do
        create(:tournament_match, tournament_round: tour.tournament_round, host_club: club, status: :live)
        lineup = create(:lineup, tour: tour, team: match1.host)
        # named in the matchday squad but no rating yet — he can still come on
        create(:match_player, lineup: lineup,
                              round_player: create(:round_player, player: bench_player, club: club,
                                                                  tournament_round: tour.tournament_round,
                                                                  in_squad: true, score: 0))
        # left out of the squad entirely — there is nothing left to wait for
        create(:match_player, lineup: lineup,
                              round_player: create(:round_player, player: absent_player, club: club,
                                                                  tournament_round: tour.tournament_round,
                                                                  in_squad: false, score: 0))
        get match_path(match1)
      end

      it { expect(response).to be_successful }

      it 'keeps the pending marker for the player on the bench' do
        expect(response.body).to include('team-player-score-live-pending')
      end

      it 'marks the player who is not in the squad differently' do
        expect(response.body).to include('team-player-score-live-absent')
      end

      it 'names that state for the reader' do
        expect(response.body).to include(I18n.t('matches.not_in_squad'))
      end
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
end

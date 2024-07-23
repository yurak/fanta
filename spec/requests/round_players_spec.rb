RSpec.describe 'RoundPlayers' do
  describe 'GET #index' do
    let(:tournament_round) { create(:tournament_round) }
    let(:params) { nil }

    context 'when user is logged out' do
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to redirect_to('/users/sign_in') }
      it { expect(response).to have_http_status(:found) }
    end

    context 'without additional params' do
      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with national tournament' do
      let(:tournament_round) { create(:tournament_round, tournament: create(:tournament, :with_national_teams)) }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with eurocup tournament' do
      let(:tournament_round) { create(:tournament_round, :with_eurocup_tournament) }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with position param' do
      let(:params) { { position: 'T' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with national tournament and position param' do
      let(:tournament_round) { create(:tournament_round, tournament: create(:tournament, :with_national_teams)) }
      let(:params) { { position: 'T' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with eurocup tournament and position param' do
      let(:tournament_round) { create(:tournament_round, :with_eurocup_tournament) }
      let(:params) { { position: 'T' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with club order param' do
      let(:params) { { order: 'club' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with national order param' do
      let(:params) { { order: 'national' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with matches order param' do
      let(:params) { { order: 'matches' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with main_squad order param' do
      let(:params) { { order: 'main_squad' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with main_squad order param' do
      let(:params) { { order: 'main_squad' } }

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with name order param' do
      let(:params) { { order: 'name' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with base_score order param' do
      let(:params) { { order: 'base_score' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(assigns(:players)).not_to be_nil }
      it { expect(assigns(:positions)).not_to be_nil }
      it { expect(assigns(:clubs)).not_to be_nil }
    end

    context 'with club filter param' do
      let!(:round_player) { create(:round_player, tournament_round: tournament_round) }
      let(:params) { { club: round_player.player.club_id } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it { expect(response).to have_http_status(:ok) }

      it 'returns players filtered by the given club' do
        expect(assigns(:players)).to include(round_player)
      end
    end

    context 'with result_score order and multiple scored players' do
      let!(:rp_high) { create(:round_player, :with_score_seven, tournament_round: tournament_round) }
      let!(:rp_low)  { create(:round_player, :with_score_five,  tournament_round: tournament_round) }
      let(:params) { { order: 'result_score' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }

      it 'sorts players by result_score descending' do
        players = assigns(:players)
        expect(players.index(rp_high)).to be < players.index(rp_low)
      end
    end

    context 'with base_score order and multiple scored players' do
      let!(:rp_high) { create(:round_player, :with_score_seven, tournament_round: tournament_round) }
      let!(:rp_low)  { create(:round_player, :with_score_five,  tournament_round: tournament_round) }
      let(:params) { { order: 'base_score' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }

      it 'sorts players by base score descending' do
        players = assigns(:players)
        expect(players.index(rp_high)).to be < players.index(rp_low)
      end
    end

    context 'with club order and multiple scored players' do
      let(:tournament)       { create(:tournament) }
      let(:tournament_round) { create(:tournament_round, tournament: tournament) }
      let(:club_a)           { create(:club, name: 'Aaa United', tournament: tournament) }
      let(:club_z)           { create(:club, name: 'Zzz City',   tournament: tournament) }
      let!(:rp_z) do
        create(:round_player, :with_score_six, tournament_round: tournament_round,
                                               player: create(:player, club: club_z), club: club_z)
      end
      let!(:rp_a) do
        create(:round_player, :with_score_six, tournament_round: tournament_round,
                                               player: create(:player, club: club_a), club: club_a)
      end
      let(:params) { { order: 'club' } }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }

      it 'puts the alphabetically first club first' do
        expect(assigns(:players).first).to eq(rp_a)
      end

      it 'puts the alphabetically last club last' do
        expect(assigns(:players).last).to eq(rp_z)
      end
    end

    context 'with fanta tournament, matches order, and deadlined tour' do
      let(:fanta_tournament) { create(:fanta_tournament) }
      let(:tournament_round) { create(:tournament_round, tournament: fanta_tournament) }
      let!(:rp_more) { create(:round_player, :with_score_six, tournament_round: tournament_round) }
      let(:params)   { { order: 'matches' } }

      login_user
      before do
        rp_less = create(:round_player, :with_score_six, tournament_round: tournament_round)
        tour    = create(:locked_tour, tournament_round: tournament_round)
        lineup  = create(:lineup, tour: tour)
        create(:match_player, round_player: rp_more, lineup: lineup)
        create(:match_player, round_player: rp_more, lineup: lineup)
        create(:match_player, round_player: rp_less, lineup: lineup)
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it { expect(response).to have_http_status(:ok) }

      it 'sorts players by total appearances descending' do
        expect(assigns(:players).first).to eq(rp_more)
      end
    end

    context 'with fanta tournament, main_squad order, and deadlined tour' do
      let(:fanta_tournament) { create(:fanta_tournament) }
      let(:tournament_round) { create(:tournament_round, tournament: fanta_tournament) }
      let!(:rp_main) { create(:round_player, :with_score_six, tournament_round: tournament_round) }
      let(:params)   { { order: 'main_squad' } }

      login_user
      before do
        rp_bench = create(:round_player, :with_score_six, tournament_round: tournament_round)
        tour     = create(:locked_tour, tournament_round: tournament_round)
        lineup   = create(:lineup, tour: tour)
        create(:match_player, round_player: rp_main, lineup: lineup, real_position: 'Dc')
        create(:match_player, round_player: rp_bench, lineup: lineup)
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }
      it { expect(response).to render_template(:index) }

      it { expect(response).to have_http_status(:ok) }

      it 'sorts players by main squad appearances descending' do
        expect(assigns(:players).first).to eq(rp_main)
      end
    end

    context 'with fanta tournament, matches order, and non-deadlined tour' do
      let(:fanta_tournament) { create(:fanta_tournament) }
      let(:tournament_round) { create(:tournament_round, tournament: fanta_tournament) }
      let(:params) { { order: 'matches' } }

      login_user
      before do
        create(:round_player, :with_score_six, tournament_round: tournament_round)
        create(:round_player, :with_score_six, tournament_round: tournament_round)
        create(:set_lineup_tour, tournament_round: tournament_round)
        get tournament_round_round_players_path(tournament_round, params)
      end

      it { expect(response).to be_successful }

      it { expect(assigns(:players)).not_to be_nil }
    end

    context 'with national tournament, clubs sorted by name' do
      let(:national_tournament) { create(:tournament, :with_national_teams) }
      let(:tournament_round)    { create(:tournament_round, tournament: national_tournament) }

      login_user
      before do
        get tournament_round_round_players_path(tournament_round)
      end

      it { expect(response).to be_successful }

      it 'returns national teams sorted by name' do
        clubs = assigns(:clubs)
        expect(clubs.map(&:name)).to eq(clubs.map(&:name).sort)
      end
    end
  end
end

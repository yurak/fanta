RSpec.describe 'Api::RoundPlayers' do
  let(:tournament)       { create(:fanta_tournament) }
  let(:tournament_round) { create(:tournament_round, tournament: tournament) }

  def get_index(params = {})
    get "/api/tournament_rounds/#{tournament_round.id}/round_players", params: params
  end

  describe 'GET /api/tournament_rounds/:id/round_players' do
    context 'without filters' do
      let!(:round_player) { create(:round_player, :with_score_six, tournament_round: tournament_round) }

      before { get_index }

      it { expect(response).to have_http_status(:ok) }

      it 'returns pagination meta' do
        expect(response.parsed_body['meta']['page']).to include('current_page' => 1)
      end

      it 'returns the requested round player' do
        expect(response.parsed_body['data'].first).to include('id' => round_player.id)
      end

      it 'returns the round player row fields' do
        row = response.parsed_body['data'].first
        expect(row).to include('id', 'player_id', 'name', 'avatar_path', 'base_score', 'result_score', 'club')
      end
    end

    context 'with a position filter' do
      let!(:goalkeeper) { create(:round_player, :with_pos_por, :with_score_six, tournament_round: tournament_round) }
      let!(:forward)    { create(:round_player, :with_pos_a, :with_score_six, tournament_round: tournament_round) }
      let(:ids)         { response.parsed_body['data'].pluck('id') }

      # The React picker sends classic codes (GK), mapped to Position#human_name.
      before { get_index(filter: { position: ['GK'] }) }

      it 'includes players in the filtered position' do
        expect(ids).to include(goalkeeper.id)
      end

      it 'excludes players not in the filtered position' do
        expect(ids).not_to include(forward.id)
      end
    end

    context 'with players appearing in two leagues' do
      let(:league_a)      { create(:active_league, tournament: tournament, season: tournament_round.season) }
      let(:league_b)      { create(:active_league, tournament: tournament, season: tournament_round.season) }
      let!(:round_player) { create(:round_player, :with_score_six, tournament_round: tournament_round) }

      before do
        tour_a   = create(:locked_tour, tournament_round: tournament_round, league: league_a)
        tour_b   = create(:locked_tour, tournament_round: tournament_round, league: league_b)
        lineup_a = create(:lineup, tour: tour_a, team: create(:team, league: league_a))
        lineup_b = create(:lineup, tour: tour_b, team: create(:team, league: league_b))
        create(:match_player, round_player: round_player, lineup: lineup_a)
        create(:match_player, round_player: round_player, lineup: lineup_a)
        create(:match_player, round_player: round_player, lineup: lineup_b)
      end

      it 'aggregates appearances across all leagues by default' do
        get_index
        row = response.parsed_body['data'].find { |r| r['id'] == round_player.id }
        expect(row['appearances']).to eq(3)
      end

      it 'scopes appearances to the selected league' do
        get_index(filter: { league_id: league_a.id })
        row = response.parsed_body['data'].find { |r| r['id'] == round_player.id }
        expect(row['appearances']).to eq(2)
      end
    end

    context 'with a club filter' do
      let(:club_a) { create(:club, tournament: tournament) }
      let(:club_b) { create(:club, tournament: tournament) }
      let!(:rp_a) do
        create(:round_player, :with_score_six, tournament_round: tournament_round,
                                               player: create(:player, club: club_a), club: club_a)
      end
      let!(:rp_b) do
        create(:round_player, :with_score_six, tournament_round: tournament_round,
                                               player: create(:player, club: club_b), club: club_b)
      end
      let(:ids) { response.parsed_body['data'].pluck('id') }

      before { get_index(filter: { club_id: [club_a.id] }) }

      it 'includes players from the selected club' do
        expect(ids).to include(rp_a.id)
      end

      it 'excludes players from other clubs' do
        expect(ids).not_to include(rp_b.id)
      end
    end

    context 'when ordering by appearances before the deadline' do
      let!(:rp_high) { create(:round_player, :with_score_seven, tournament_round: tournament_round) }
      let!(:rp_low)  { create(:round_player, :with_score_five,  tournament_round: tournament_round) }

      before { get_index(order: { field: 'appearances', direction: 'desc' }) }

      it { expect(response).to have_http_status(:ok) }

      it 'falls back to result_score ordering' do
        ids = response.parsed_body['data'].pluck('id')
        expect(ids.index(rp_high.id)).to be < ids.index(rp_low.id)
      end
    end

    context 'when ordering by result_score descending' do
      let!(:rp_high) { create(:round_player, :with_score_seven, tournament_round: tournament_round) }
      let!(:rp_low)  { create(:round_player, :with_score_five,  tournament_round: tournament_round) }

      before { get_index(order: { field: 'result_score', direction: 'desc' }) }

      it 'sorts players by result_score descending' do
        ids = response.parsed_body['data'].pluck('id')
        expect(ids.index(rp_high.id)).to be < ids.index(rp_low.id)
      end
    end
  end

  describe 'GET /api/tournament_rounds/:id/round_players/meta' do
    let!(:league) { create(:active_league, tournament: tournament, season: tournament_round.season) }
    let(:club)    { create(:club, tournament: tournament) }

    before do
      create(:round_player, :with_score_six, tournament_round: tournament_round,
                                             player: create(:player, club: club), club: club)
      get "/api/tournament_rounds/#{tournament_round.id}/round_players/meta"
    end

    it { expect(response).to have_http_status(:ok) }

    it 'returns round meta' do
      expect(response.parsed_body['data']).to include('tournament_name', 'number', 'national', 'fanta', 'deadlined')
    end

    it 'returns the round leagues for the filter dropdown' do
      league_ids = response.parsed_body['data']['leagues'].pluck('id')
      expect(league_ids).to include(league.id)
    end

    it 'returns the round clubs for the filter dropdown' do
      club_ids = response.parsed_body['data']['clubs'].pluck('id')
      expect(club_ids).to include(club.id)
    end
  end
end

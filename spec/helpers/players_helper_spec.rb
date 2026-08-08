RSpec.describe PlayersHelper do
  describe '#available_for_substitution(match_player, bench_players)' do
    let(:match_player) { nil }
    let(:bench_players) { nil }

    context 'without match_player and bench_players' do
      it 'returns empty array' do
        expect(helper.available_for_substitution(match_player, bench_players)).to eq([])
      end
    end

    context 'with bench_players and without match_player' do
      let(:mp_one) { create(:match_player, round_player: create(:round_player, :with_pos_e, :with_score_six)) }
      let(:mp_two) { create(:match_player, round_player: create(:round_player, :with_pos_c, :with_score_six)) }
      let(:bench_players) { [mp_one, mp_two] }

      it 'returns empty array' do
        expect(helper.available_for_substitution(match_player, bench_players)).to eq([])
      end
    end

    context 'without bench_players and with match_player' do
      let(:match_player) { create(:m_match_player) }

      it 'returns empty array' do
        expect(helper.available_for_substitution(match_player, bench_players)).to eq([])
      end
    end

    context 'with bench_players where one is available for match_player substitution' do
      let(:mp_one) { create(:match_player, round_player: create(:round_player, :with_pos_w, :with_score_six)) }
      let(:mp_two) { create(:match_player, round_player: create(:round_player, :with_pos_c, :with_score_six)) }
      let(:bench_players) { [mp_one, mp_two] }
      let(:match_player) { create(:m_match_player) }

      it 'returns array with bench_players data' do
        expect(helper.available_for_substitution(match_player, bench_players)).to eq([[mp_two, '1.5']])
      end
    end

    context 'with bench_players where multiple are available for match_player substitution' do
      let(:mp_one) { create(:match_player, round_player: create(:round_player, :with_pos_dc, :with_score_seven)) }
      let(:mp_two) { create(:match_player, round_player: create(:round_player, :with_pos_c, :with_score_six)) }
      let(:bench_players) { [mp_one, mp_two] }
      let(:match_player) { create(:m_match_player) }

      it 'returns array with bench_players data' do
        expect(helper.available_for_substitution(match_player, bench_players)).to eq([[mp_one, '3.0'], [mp_two, '1.5']])
      end
    end

    context 'with bench_players when all are unavailable for match_player substitution' do
      let(:mp_one) { create(:match_player, round_player: create(:round_player, :with_pos_dd, :with_score_seven)) }
      let(:mp_two) { create(:match_player, round_player: create(:round_player, :with_pos_a, :with_score_six)) }
      let(:bench_players) { [mp_one, mp_two] }
      let(:match_player) { create(:m_match_player) }

      it 'returns array with match_players data' do
        expect(helper.available_for_substitution(match_player, bench_players)).to eq([])
      end
    end
  end

  describe '#available_for_select(team)' do
    let(:team) { create(:team, :with_players) }

    context 'when team without players' do
      let(:team) { create(:team) }

      it 'returns empty array' do
        expect(helper.available_for_select(team)).to eq([])
      end
    end

    context 'when team with players' do
      it 'returns players sorted by position' do
        expect(helper.available_for_select(team)).to eq(team.players.sort_by(&:position_sequence_number))
      end
    end
  end

  describe '#available_by_slot(team, slot)' do
    let(:team) { create(:team, :with_players_by_pos) }
    let(:slot) { create(:slot, position: 'M') }

    context 'when team without players' do
      let(:team) { create(:team) }

      it 'returns empty hash' do
        expect(helper.available_by_slot(team, slot)).to eq({})
      end
    end

    context 'when slot nil' do
      let(:slot) { nil }

      it 'returns empty hash' do
        expect(helper.available_by_slot(team, slot)).to eq({})
      end
    end

    context 'when slot without position' do
      let(:slot) { create(:slot) }

      it 'returns empty hash' do
        expect(helper.available_by_slot(team, slot)).to eq({})
      end
    end

    context 'with slot and team with players' do
      it 'returns players without malus' do
        expect(helper.available_by_slot(team, slot)).to have_key('0')
      end

      it 'returns players with malus 1,5' do
        expect(helper.available_by_slot(team, slot)).to have_key('1.5')
      end

      it 'returns players with malus 3' do
        expect(helper.available_by_slot(team, slot)).to have_key('3.0')
      end
    end
  end

  describe '#tournament_round_players(tournament_round, real_position)' do
    context 'with mantra tournament' do
      let(:tournament_round) { create(:tournament_round) }

      it 'returns empty array' do
        expect(helper.tournament_round_players(tournament_round, 'Por')).to eq([])
      end
    end

    context 'with national tournament with players' do
      let(:tournament_round) { create(:tournament_round) }
      let(:team) { create(:national_team) }

      it 'returns players for this round by position' do
        create(:national_match, host_team: team, tournament_round: tournament_round)
        players = create_list(:player, 2, :with_pos_por, national_team: team)

        expect(helper.tournament_round_players(tournament_round, 'Por').first).to eq([team, players])
      end
    end
  end

  describe '#player_by_mp(match_player, team_module)' do
    let(:match_player) { create(:match_player, :with_real_position) }
    let(:team_module) { TeamModule.first }
    let(:match_player_double) { double }

    context 'when the match player has no round_player_id' do
      let(:mp_without_rp) { double(object: double(round_player_id: nil)) }

      it 'returns nil' do
        expect(helper.player_by_mp(mp_without_rp, team_module)).to be_nil
      end
    end

    context 'when player position does not include module position' do
      before do
        allow(match_player_double).to receive_messages(object: match_player, index: 2)
      end

      it 'returns nil' do
        expect(helper.player_by_mp(match_player_double, team_module)).to be_nil
      end
    end

    context 'when player position includes module position' do
      let(:match_player_double2) { double }

      before do
        allow(match_player_double).to receive_messages(object: match_player, index: 9)
      end

      it 'returns player' do
        expect(helper.player_by_mp(match_player_double, team_module)).to eq(match_player.player)
      end
    end
  end

  describe '#subs_string(match_player)' do
    let(:out_rp) { create(:round_player) }
    let(:match_player) { create(:match_player) }

    before do
      create(:substitute, main_mp: match_player, out_rp: out_rp, subs_by: :manual)
    end

    context 'without current_user' do
      before { allow(helper).to receive(:current_user).and_return(nil) }

      it 'returns replaced string without subs_by' do
        expect(helper.subs_string(match_player)).to eq("Replaced: #{out_rp.full_name_reverse}")
      end
    end

    context 'with regular user' do
      before { allow(helper).to receive(:current_user).and_return(create(:user)) }

      it 'returns replaced string without subs_by' do
        expect(helper.subs_string(match_player)).to eq("Replaced: #{out_rp.full_name_reverse}")
      end
    end

    context 'with moderator' do
      before { allow(helper).to receive(:current_user).and_return(create(:moderator)) }

      it 'returns replaced string with subs_by' do
        expect(helper.subs_string(match_player)).to eq("Replaced: #{out_rp.full_name_reverse} by manual")
      end
    end

    context 'with admin' do
      before { allow(helper).to receive(:current_user).and_return(create(:admin)) }

      it 'returns replaced string with subs_by' do
        expect(helper.subs_string(match_player)).to eq("Replaced: #{out_rp.full_name_reverse} by manual")
      end
    end

    context 'when match_player has no substitutions' do
      let(:empty_match_player) { create(:match_player) }

      before { allow(helper).to receive(:current_user).and_return(nil) }

      it 'returns replaced string with nil player name' do
        expect(helper.subs_string(empty_match_player)).to eq('Replaced: ')
      end
    end
  end

  describe '#module_link(lineup, team_module)' do
    let(:team_module) { TeamModule.first }

    context 'when lineup exists' do
      let(:lineup) { create(:lineup) }

      it 'returns edit path with team_module_id' do
        expect(helper.module_link(lineup, team_module)).to eq(
          edit_team_lineup_path(lineup.team, lineup, team_module_id: team_module.id)
        )
      end
    end

    context 'when lineup is new' do
      let(:tour) { create(:tour) }
      let(:team) { create(:team) }
      let(:lineup) { Lineup.new(team: team, tour: tour) }

      it 'returns new path with team_module_id and tour_id' do
        expect(helper.module_link(lineup, team_module)).to eq(
          new_team_lineup_path(team, team_module_id: team_module.id, tour_id: tour.id)
        )
      end
    end
  end

  describe '#player_by_source_data(player_data)' do
    context 'when sofascore_id is present' do
      let!(:player) { create(:player, sofascore_id: 12_345) }

      it 'returns player by sofascore_id' do
        expect(helper.player_by_source_data('sofascore_id' => 12_345)).to eq(player)
      end

      it 'ignores fotmob_id when sofascore_id is present' do
        create(:player, fotmob_id: 99_999)
        expect(helper.player_by_source_data('sofascore_id' => 12_345, 'fotmob_id' => 99_999)).to eq(player)
      end
    end

    context 'when only fotmob_id is present' do
      let!(:player) { create(:player, fotmob_id: 67_890) }

      it 'returns player by fotmob_id' do
        expect(helper.player_by_source_data('fotmob_id' => 67_890)).to eq(player)
      end
    end

    context 'when sofascore_id does not match any player' do
      it 'returns nil' do
        expect(helper.player_by_source_data('sofascore_id' => 99_999)).to be_nil
      end
    end

    context 'when fotmob_id does not match any player' do
      it 'returns nil' do
        expect(helper.player_by_source_data('fotmob_id' => 99_999)).to be_nil
      end
    end

    context 'when neither sofascore_id nor fotmob_id is present' do
      it 'returns nil' do
        expect(helper.player_by_source_data({})).to be_nil
      end
    end
  end

  describe '#players_last_rounds_form(players, current_round)' do
    let(:tournament) { create(:tournament) }
    let(:season) { create(:season) }
    let(:player) { create(:player) }
    let(:current_round) { create(:tournament_round, tournament: tournament, season: season, number: 3) }
    let(:two_rounds_ago) { create(:tournament_round, tournament: tournament, season: season, number: 1) }
    let(:previous_round) { create(:tournament_round, tournament: tournament, season: season, number: 2) }

    context 'without a current round' do
      it 'returns empty hash' do
        expect(helper.players_last_rounds_form([player], nil)).to eq({})
      end
    end

    context 'without players' do
      it 'returns empty hash' do
        expect(helper.players_last_rounds_form([], current_round)).to eq({})
      end
    end

    context 'when there are no prior rounds' do
      let(:current_round) { create(:tournament_round, tournament: tournament, season: season, number: 1) }

      it 'returns empty hash' do
        expect(helper.players_last_rounds_form([player], current_round)).to eq({})
      end
    end

    context 'when fewer than five prior rounds exist' do
      let(:cells) { helper.players_last_rounds_form([player], current_round)[player.id] }

      before do
        create(:round_player, player: player, tournament_round: two_rounds_ago, in_squad: true, played_minutes: 90, score: 7.0)
        create(:round_player, player: player, tournament_round: previous_round, in_squad: true, played_minutes: 30, score: 6.0)
      end

      it 'pads missing rounds on the left, oldest to newest' do
        expect(cells.pluck(:state)).to eq(%w[empty empty empty full part])
      end

      it 'fills the score of the played rounds' do
        expect(cells.last(2).pluck(:score)).to eq(%w[7 6])
      end
    end

    context 'when mapping the previous round state' do
      let(:current_round) { create(:tournament_round, tournament: tournament, season: season, number: 2) }

      before { two_rounds_ago } # the prior round must exist even when the player has no round_player in it

      def last_state
        helper.players_last_rounds_form([player], current_round)[player.id].last[:state]
      end

      it 'is bench when in squad without minutes' do
        create(:round_player, player: player, tournament_round: two_rounds_ago, in_squad: true, played_minutes: 0)
        expect(last_state).to eq('bench')
      end

      it 'is out when not in squad' do
        create(:round_player, player: player, tournament_round: two_rounds_ago, in_squad: false)
        expect(last_state).to eq('out')
      end

      it 'is out when no round_player exists' do
        expect(last_state).to eq('out')
      end
    end
  end

  describe '#form_rounds(current_round, count)' do
    let(:tournament) { create(:tournament) }
    let(:season) { create(:season) }
    let(:current_round) { create(:tournament_round, tournament: tournament, season: season, number: 7) }

    before do
      (1..6).each { |number| create(:tournament_round, tournament: tournament, season: season, number: number) }
      create(:tournament_round, tournament: tournament, season: create(:season), number: 4) # other season
      create(:tournament_round, tournament: create(:tournament), season: season, number: 4) # other tournament
    end

    it 'returns up to count prior rounds of the same tournament and season, oldest to newest' do
      expect(helper.form_rounds(current_round, 5).map(&:number)).to eq([2, 3, 4, 5, 6])
    end
  end

  describe '#player_form_cell(round_player)' do
    it 'is out when the round_player is nil' do
      expect(helper.player_form_cell(nil)).to eq({ state: 'out' })
    end

    it 'is out when the player was not in the squad' do
      expect(helper.player_form_cell(build(:round_player, in_squad: false))[:state]).to eq('out')
    end

    it 'is bench when in the squad without minutes' do
      expect(helper.player_form_cell(build(:round_player, in_squad: true, played_minutes: 0))[:state]).to eq('bench')
    end

    it 'is part when played fewer than 60 minutes' do
      expect(helper.player_form_cell(build(:round_player, in_squad: true, played_minutes: 45, score: 6.0))[:state]).to eq('part')
    end

    it 'is full when played 60 minutes or more' do
      expect(helper.player_form_cell(build(:round_player, in_squad: true, played_minutes: 90, score: 7.0))[:state]).to eq('full')
    end
  end

  describe '#player_form_score(round_player)' do
    it 'uses final_score when it is set' do
      expect(helper.player_form_score(build(:round_player, final_score: 8.0, score: 6.0))).to eq('8')
    end

    it 'falls back to the rating when final_score is not set' do
      expect(helper.player_form_score(build(:round_player, final_score: 0, score: 6.53))).to eq('6.5')
    end

    it 'is nil when there is no score' do
      expect(helper.player_form_score(build(:round_player, final_score: 0, score: 0))).to be_nil
    end
  end

  describe '#player_form_row(player, rounds, cells, pad)' do
    let(:player) { create(:player) }
    let(:round) { create(:tournament_round) }
    let(:round_player) { create(:round_player, player: player, tournament_round: round, in_squad: true, played_minutes: 90, score: 7.0) }

    it 'prepends the padding to the mapped cells' do
      cells = { [player.id, round.id] => round_player }
      row = helper.player_form_row(player, [round], cells, [{ state: 'empty' }])
      expect(row.pluck(:state)).to eq(%w[empty full])
    end
  end

  describe '#out_player_name(match_player)' do
    let(:match_player) { create(:match_player) }

    context 'with a substitution' do
      let(:out_rp) { create(:round_player) }

      before { create(:substitute, main_mp: match_player, out_rp: out_rp, subs_by: :manual) }

      it 'returns the replaced player name' do
        expect(helper.out_player_name(match_player)).to eq(out_rp.full_name_reverse)
      end
    end

    context 'without a substitution' do
      it 'returns nil' do
        expect(helper.out_player_name(match_player)).to be_nil
      end
    end
  end

  describe '#subs_by_name(match_player)' do
    let(:match_player) { create(:match_player) }

    context 'with a substitution' do
      before { create(:substitute, main_mp: match_player, out_rp: create(:round_player), subs_by: :manual) }

      it 'returns who made the substitution' do
        expect(helper.subs_by_name(match_player)).to eq('manual')
      end
    end

    context 'without a substitution' do
      it 'returns nil' do
        expect(helper.subs_by_name(match_player)).to be_nil
      end
    end
  end

  describe '#current_season' do
    it 'returns the last season' do
      create(:season)
      expect(helper.current_season).to eq(Season.last)
    end
  end

  describe '#user_tournament_team(tournament_id)' do
    let(:tournament) { Tournament.last }

    context 'without current_user' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'returns false' do
        expect(helper.user_tournament_team(tournament.id)).to be(false)
      end
    end

    context 'with logged user and without team in tournament' do
      before do
        allow(helper).to receive(:current_user).and_return(create(:user))
      end

      it 'returns nil' do
        expect(helper.user_tournament_team(tournament.id)).to be_nil
      end
    end

    context 'with logged user and team in tournament' do
      let(:user) { create(:user) }
      let!(:team) { create(:team, league: create(:league, tournament: tournament), user: user) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns team from tournament' do
        expect(helper.user_tournament_team(tournament.id)).to eq(team)
      end
    end
  end
end

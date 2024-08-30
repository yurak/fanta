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

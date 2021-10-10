RSpec.describe PlayersHelper, type: :helper do
  describe '#available_for_substitution(match_player, bench_players)' do
    let(:match_player) { nil }
    let(:bench_players) { nil }

    context 'without match_player and bench_players' do
      it 'returns empty array' do
        expect(helper.available_for_substitution(match_player, bench_players)).to eq([])
      end
    end

    context 'with bench_players and without match_player' do
      let(:mp1) { create(:match_player, round_player: create(:round_player, :with_pos_e, :with_score_six)) }
      let(:mp2) { create(:match_player, round_player: create(:round_player, :with_pos_c, :with_score_six)) }
      let(:bench_players) { [mp1, mp2] }

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
      let(:mp1) { create(:match_player, round_player: create(:round_player, :with_pos_e, :with_score_six)) }
      let(:mp2) { create(:match_player, round_player: create(:round_player, :with_pos_c, :with_score_six)) }
      let(:bench_players) { [mp1, mp2] }
      let(:match_player) { create(:m_match_player) }

      it 'returns array with bench_players data' do
        expect(helper.available_for_substitution(match_player, bench_players)).to eq([[mp2, '1.5']])
      end
    end

    context 'with bench_players where multiple are available for match_player substitution' do
      let(:mp1) { create(:match_player, round_player: create(:round_player, :with_pos_dc, :with_score_seven)) }
      let(:mp2) { create(:match_player, round_player: create(:round_player, :with_pos_c, :with_score_six)) }
      let(:bench_players) { [mp1, mp2] }
      let(:match_player) { create(:m_match_player) }

      it 'returns array with bench_players data' do
        expect(helper.available_for_substitution(match_player, bench_players)).to eq([[mp1, '3.0'], [mp2, '1.5']])
      end
    end

    context 'with bench_players when all are unavailable for match_player substitution' do
      let(:mp1) { create(:match_player, round_player: create(:round_player, :with_pos_e, :with_score_seven)) }
      let(:mp2) { create(:match_player, round_player: create(:round_player, :with_pos_a, :with_score_six)) }
      let(:bench_players) { [mp1, mp2] }
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

    context 'with slot and team with players ' do
      it 'returns players without malus' do
        expect(helper.available_by_slot(team, slot)).to have_key('')
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

    context 'with eurocup tournament without players' do
      let(:tournament_round) { create(:tournament_round, tournament: Tournament.find_by(eurocup: true)) }

      it 'returns empty array' do
        expect(helper.tournament_round_players(tournament_round, 'Por')).to eq([])
      end
    end

    context 'with eurocup tournament with players' do
      let(:tournament) { Tournament.find_by(eurocup: true) }
      let(:tournament_round) { create(:tournament_round, tournament: tournament) }
      let(:club) { create(:club, ec_tournament: tournament) }

      it 'returns players for this round by position' do
        create(:tournament_match, host_club: club, tournament_round: tournament_round)
        players = create_list(:player, 2, :with_pos_por, club: club)

        expect(helper.tournament_round_players(tournament_round, 'Por')).to eq(players)
      end
    end

    context 'with national tournament with players' do
      let(:tournament_round) { create(:tournament_round) }
      let(:team) { create(:national_team) }
      # let(:matches) { create(:national_match, host_team: team, tournament_round: tournament_round) }

      it 'returns players for this round by position' do
        create(:national_match, host_team: team, tournament_round: tournament_round)
        players = create_list(:player, 2, :with_pos_por, national_team: team)

        expect(helper.tournament_round_players(tournament_round, 'Por')).to eq(players)
      end
    end
  end

  describe '#player_by_mp(match_player, team_module)' do
    let(:match_player) { create(:match_player, :with_real_position) }
    let(:team_module) { TeamModule.first }
    let(:match_player_double) { double }

    context 'when player position does not include module position' do
      before do
        allow(match_player_double).to receive(:object).and_return(match_player)
        allow(match_player_double).to receive(:index).and_return(2)
      end

      it 'returns nil' do
        expect(helper.player_by_mp(match_player_double, team_module)).to eq(nil)
      end
    end

    context 'when player position includes module position' do
      let(:match_player_double2) { double }

      before do
        allow(match_player_double).to receive(:object).and_return(match_player)
        allow(match_player_double).to receive(:index).and_return(9)
      end

      it 'returns player' do
        expect(helper.player_by_mp(match_player_double, team_module)).to eq(match_player.player)
      end
    end
  end

  describe '#module_link(lineup, team_module)' do
    it 'is a pending example for module_link'
  end

  describe '#auction_step(league)' do
    let(:league) { create(:league) }

    context 'without transfers' do
      it 'returns zero' do
        expect(helper.auction_step(league)).to eq(0)
      end
    end

    context 'without teams and with transfers' do
      it 'returns zero' do
        create_list(:transfer, 3, league: league)

        expect(helper.auction_step(league)).to eq(0)
      end
    end

    context 'with teams and transfers' do
      it 'returns active team id' do
        create_list(:transfer, 2, league: league)
        teams = create_list(:team, 6, league: league)

        expect(helper.auction_step(league)).to eq(teams[2].id)
      end
    end
  end
end

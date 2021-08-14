RSpec.describe PlayersHelper, type: :helper do
  describe '#available_for_substitution(match_players, positions)' do
    let(:match_players) { nil }
    let(:positions) { nil }

    context 'without match_players and positions' do
      it 'returns empty array' do
        expect(helper.available_for_substitution(match_players, positions)).to eq([])
      end
    end

    context 'with match_players and without positions' do
      let(:mp1) { create(:match_player, round_player: create(:round_player, :with_pos_e, :with_score_six)) }
      let(:mp2) { create(:match_player, round_player: create(:round_player, :with_pos_c, :with_score_six)) }
      let(:match_players) { [mp1, mp2] }

      it 'returns empty array' do
        expect(helper.available_for_substitution(match_players, positions)).to eq([])
      end
    end

    context 'without match_players and with positions' do
      let(:positions) { ['Dc'] }

      it 'returns empty array' do
        expect(helper.available_for_substitution(match_players, positions)).to eq([])
      end
    end

    context 'with match_players where one is available for substitution positions' do
      let(:mp1) { create(:match_player, round_player: create(:round_player, :with_pos_e, :with_score_six)) }
      let(:mp2) { create(:match_player, round_player: create(:round_player, :with_pos_c, :with_score_six)) }
      let(:match_players) { [mp1, mp2] }
      let(:positions) { %w[Dc M C] }

      it 'returns array with match_players data' do
        expect(helper.available_for_substitution(match_players, positions))
          .to eq([["(#{mp2.position_names.join('-')}) #{mp2.player.name} - #{mp2.score}", mp2.id]])
      end
    end

    context 'with match_players where multiple are available for substitution positions' do
      let(:mp1) { create(:match_player, round_player: create(:round_player, :with_pos_dc, :with_score_seven)) }
      let(:mp2) { create(:match_player, round_player: create(:round_player, :with_pos_c, :with_score_six)) }
      let(:match_players) { [mp1, mp2] }
      let(:positions) { %w[Dc M C] }

      it 'returns array with match_players data' do
        expect(helper.available_for_substitution(match_players, positions))
          .to eq([["(#{mp1.position_names.join('-')}) #{mp1.player.name} - #{mp1.score}", mp1.id],
                  ["(#{mp2.position_names.join('-')}) #{mp2.player.name} - #{mp2.score}", mp2.id]])
      end
    end

    context 'with match_players when all are unavailable for substitution positions' do
      let(:mp1) { create(:match_player, round_player: create(:round_player, :with_pos_e, :with_score_seven)) }
      let(:mp2) { create(:match_player, round_player: create(:round_player, :with_pos_a, :with_score_six)) }
      let(:match_players) { [mp1, mp2] }
      let(:positions) { %w[Dc M C] }

      it 'returns array with match_players data' do
        expect(helper.available_for_substitution(match_players, positions))
          .to eq([])
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
    it 'is a pending example for tournament_round_players'
  end

  describe '#player_by_mp(match_player)' do
    it 'is a pending example for player_by_mp'
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

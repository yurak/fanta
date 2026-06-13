RSpec.describe Lineups::Cloner do
  describe '#call' do
    subject(:service_call) { described_class.new(team, target_tour, options).call }

    let(:options) { {} }
    let(:league) { create(:league) }
    let(:team) { create(:team, league: league) }
    let(:target_tournament_round) { create(:tournament_round, tournament: league.tournament) }
    let(:target_tour) { create(:tour, league: league, tournament_round: target_tournament_round) }

    context 'when team has no previous lineup' do
      it 'returns false' do
        expect(service_call).to be(false)
      end

      it 'does not create lineup' do
        expect { service_call }.not_to change(Lineup, :count)
      end
    end

    context 'when team has no previous lineup in this league' do
      let(:another_league) { create(:league) }

      before do
        create(:lineup, team: team, tour: create(:tour, league: another_league))
      end

      it 'returns false' do
        expect(service_call).to be(false)
      end

      it 'does not create a lineup' do
        expect { service_call }.not_to change(Lineup, :count)
      end
    end

    context 'when lineup for target tour already exists' do
      before do
        create(:lineup, team: team, tour: create(:tour, league: league))
        create(:lineup, team: team, tour: target_tour)
      end

      it 'returns false' do
        expect(service_call).to be(false)
      end
    end

    context 'when cloning is allowed' do
      let(:clonable_setup) do
        old_tournament_round = create(:tournament_round, tournament: league.tournament)
        old_tour = create(:tour, league: league, tournament_round: old_tournament_round)

        old_lineup = create(
          :lineup,
          team: team,
          tour: old_tour,
          final_score: 77,
          final_goals: 3,
          substitutes: '[{"main":1}]',
          creation_type: :manual
        )

        regular_player = create(:player)
        main_player = create(:player)
        reserve_player = create(:player)

        team.players << [regular_player, main_player, reserve_player]

        regular_old_rp = create(:round_player, tournament_round: old_tournament_round, player: regular_player)
        main_old_rp = create(:round_player, tournament_round: old_tournament_round, player: main_player)
        reserve_old_rp = create(:round_player, tournament_round: old_tournament_round, player: reserve_player)

        create(:match_player, lineup: old_lineup, round_player: regular_old_rp, real_position: 'Dc')
        main_mp = create(:match_player, lineup: old_lineup, round_player: main_old_rp, real_position: 'A')
        reserve_mp = create(:match_player, lineup: old_lineup, round_player: reserve_old_rp, real_position: 'Por')

        create(:substitute, main_mp: main_mp, reserve_mp: reserve_mp, out_rp: main_old_rp, in_rp: reserve_old_rp)

        existing_target_rp = create(:round_player, tournament_round: target_tournament_round, player: regular_player)

        {
          regular_player: regular_player,
          main_player: main_player,
          reserve_player: reserve_player,
          existing_target_rp: existing_target_rp
        }
      end

      before do
        clonable_setup
      end

      it 'creates a new lineup' do
        expect { service_call }.to change(Lineup, :count).by(1)
      end

      it 'creates cloned match players' do
        expect { service_call }.to change(MatchPlayer, :count).by(3)
      end

      context 'when lineup is cloned' do
        let(:cloned_lineup) { target_tour.lineups.find_by(team_id: team.id) }

        before do
          service_call
        end

        it 'resets final_score' do
          expect(cloned_lineup.final_score).to eq(0)
        end

        it 'resets final_goals' do
          expect(cloned_lineup.final_goals).to be_nil
        end

        it 'resets substitutes' do
          expect(cloned_lineup.substitutes).to be_nil
        end

        it 'sets copied creation_type by default' do
          expect(cloned_lineup).to be_copied
        end

        it 'keeps regular player for regular match player' do
          regular_cloned_mp = cloned_lineup.match_players.find_by(real_position: 'Dc')

          expect(regular_cloned_mp.player).to eq(clonable_setup[:regular_player])
        end

        it 'uses reserve player for main-substituted match player' do
          main_cloned_mp = cloned_lineup.match_players.find_by(real_position: 'A')

          expect(main_cloned_mp.player).to eq(clonable_setup[:reserve_player])
        end

        it 'uses main player for reserve-substituted match player' do
          reserve_cloned_mp = cloned_lineup.match_players.find_by(real_position: 'Por')

          expect(reserve_cloned_mp.player).to eq(clonable_setup[:main_player])
        end

        it 'reuses existing round player in target tournament round' do
          regular_cloned_mp = cloned_lineup.match_players.find_by(real_position: 'Dc')

          expect(regular_cloned_mp.round_player.id).to eq(clonable_setup[:existing_target_rp].id)
        end

        it 'creates round players only for target tournament round' do
          tournament_round_ids = cloned_lineup.match_players.joins(:round_player).pluck('round_players.tournament_round_id').uniq

          expect(tournament_round_ids).to eq([target_tournament_round.id])
        end
      end

      context 'with auto_cloned option' do
        let(:options) { { auto_cloned: true } }

        it 'sets creation_type to auto_cloned' do
          service_call

          expect(target_tour.lineups.find_by(team_id: team.id)).to be_auto_cloned
        end
      end
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context 'when some players left the team' do
      let(:old_tournament_round) { create(:tournament_round, tournament: league.tournament) }
      let(:old_tour) { create(:tour, league: league, tournament_round: old_tournament_round) }
      let(:old_lineup) { create(:lineup, team: team, tour: old_tour) }

      def add_main_slot(player, real_position)
        rp = create(:round_player, tournament_round: old_tournament_round, player: player)
        create(:match_player, lineup: old_lineup, round_player: rp, real_position: real_position)
      end

      def add_bench_slot(player)
        rp = create(:round_player, tournament_round: old_tournament_round, player: player)
        create(:match_player, lineup: old_lineup, round_player: rp, real_position: nil)
      end

      def cloned_lineup
        service_call
        target_tour.lineups.find_by(team_id: team.id)
      end

      context 'when main player left, pool has zero-malus replacement' do
        let(:left_player) { create(:player, :with_pos_dc) }
        let(:pool_player) { create(:player, :with_pos_dc) }

        before do
          add_main_slot(left_player, Position::CENTER_BACK)
          team.players << pool_player
        end

        it 'replaces with zero-malus player from pool' do
          mp = cloned_lineup.match_players.find_by(real_position: Position::CENTER_BACK)
          expect(mp.player).to eq(pool_player)
        end
      end

      context 'when main player left, zero-malus only on bench' do
        let(:left_player)  { create(:player, :with_pos_dc) }
        let(:bench_player) { create(:player, :with_pos_dc) }
        let(:pool_player)  { create(:player, :with_pos_ds) }

        before do
          add_main_slot(left_player, Position::CENTER_BACK)
          add_bench_slot(bench_player)
          team.players << [bench_player, pool_player]
        end

        it 'promotes bench player to main slot' do
          mp = cloned_lineup.match_players.find_by(real_position: Position::CENTER_BACK)
          expect(mp.player).to eq(bench_player)
        end

        it 'fills vacated bench slot from pool' do
          bench_players = cloned_lineup.match_players.where(real_position: nil).map(&:player)
          expect(bench_players).to include(pool_player)
        end
      end

      context 'when main player left, no zero-malus anywhere, pool has min-malus' do
        let(:left_player) { create(:player, :with_pos_dc) }
        let(:pool_player) { create(:player, :with_pos_ds) }

        before do
          add_main_slot(left_player, Position::CENTER_BACK)
          team.players << pool_player
        end

        it 'replaces with min-malus player from pool' do
          mp = cloned_lineup.match_players.find_by(real_position: Position::CENTER_BACK)
          expect(mp.player).to eq(pool_player)
        end
      end

      context 'when bench player left, pool has replacement' do
        let(:staying_player) { create(:player, :with_pos_dc) }
        let(:left_player)    { create(:player, :with_pos_ds) }
        let(:pool_player)    { create(:player, :with_pos_ds) }

        before do
          add_main_slot(staying_player, Position::CENTER_BACK)
          add_bench_slot(left_player)
          team.players << [staying_player, pool_player]
        end

        it 'fills bench slot from pool' do
          bench_players = cloned_lineup.match_players.where(real_position: nil).map(&:player)
          expect(bench_players).to include(pool_player)
        end

        it 'keeps staying main player' do
          mp = cloned_lineup.match_players.find_by(real_position: Position::CENTER_BACK)
          expect(mp.player).to eq(staying_player)
        end
      end

      context 'when slot has composite real_position (e.g. A/Pc) and bench has matching player' do
        let(:left_player)   { create(:player, :with_pos_dc) }
        let(:bench_player)  { create(:player, :with_pos_e) }
        let(:forward_player) { create(:player) }
        let(:composite_pos) { "#{Position::FORWARD}/#{Position::STRIKER}" }

        before do
          create(:player_position, player: forward_player,
                                   position: Position.find_by(name: Position::FORWARD))
          add_main_slot(left_player, composite_pos)
          add_bench_slot(bench_player)
          add_bench_slot(forward_player)
          team.players << [bench_player, forward_player]
        end

        it 'recognizes forward_player as zero-malus for composite slot and promotes them' do
          mp = cloned_lineup.match_players.find_by(real_position: composite_pos)
          expect(mp.player).to eq(forward_player)
        end

        it 'does not promote incompatible bench player to composite slot' do
          mp = cloned_lineup.match_players.find_by(real_position: composite_pos)
          expect(mp.player).not_to eq(bench_player)
        end
      end

      context 'when bench player was substituted in previous match (reserve_subs set)' do
        let(:left_player)       { create(:player, :with_pos_dc) }
        let(:bench_player)      { create(:player, :with_pos_dc) }
        let(:subbed_out_player) { create(:player, :with_pos_dc) }

        before do
          add_main_slot(left_player, Position::CENTER_BACK)

          # bench_mp has reserve_subs → player_from(bench_mp) returns subbed_out_player (NOT on team)
          # mp.player for bench_mp = bench_player (ON team, zero malus for Dc)
          subbed_rp = create(:round_player, tournament_round: old_tournament_round, player: subbed_out_player)
          bench_rp  = create(:round_player, tournament_round: old_tournament_round, player: bench_player)
          other_mp  = create(:match_player, lineup: old_lineup, round_player: subbed_rp, real_position: nil)
          bench_mp  = create(:match_player, lineup: old_lineup, round_player: bench_rp, real_position: nil)
          create(:substitute, main_mp: other_mp, reserve_mp: bench_mp, out_rp: subbed_rp, in_rp: bench_rp)

          team.players << bench_player
        end

        it 'promotes actual bench player (not substitution-adjusted) to main slot' do
          mp = cloned_lineup.match_players.find_by(real_position: Position::CENTER_BACK)
          expect(mp.player).to eq(bench_player)
        end
      end

      context 'when only incompatible bench player available (last resort fallback)' do
        let(:left_player)         { create(:player, :with_pos_dc) }
        let(:incompatible_player) { create(:player, :with_pos_por) }

        before do
          add_main_slot(left_player, Position::CENTER_BACK)
          add_bench_slot(incompatible_player)
          team.players << incompatible_player
        end

        it 'fills main slot with incompatible player rather than leaving it empty' do
          mp = cloned_lineup.match_players.find_by(real_position: Position::CENTER_BACK)
          expect(mp&.player).to eq(incompatible_player)
        end
      end

      context 'when pool and bench are exhausted' do
        let(:left_player) { create(:player, :with_pos_dc) }

        before { add_main_slot(left_player, Position::CENTER_BACK) }

        it 'skips the slot without raising' do
          expect { service_call }.not_to raise_error
        end

        it 'creates lineup with no match players for that slot' do
          expect(cloned_lineup.match_players.where(real_position: Position::CENTER_BACK)).to be_empty
        end
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context 'when old lineup has more than max players' do
      before do
        old_tournament_round = create(:tournament_round, tournament: league.tournament)
        old_tour = create(:tour, league: league, tournament_round: old_tournament_round)
        old_lineup = create(:lineup, team: team, tour: old_tour)

        players = create_list(:player, Lineup::MAX_PLAYERS + 2)
        team.players << players
        players.each do |player|
          rp = create(:round_player, tournament_round: old_tournament_round, player: player)
          create(:match_player, lineup: old_lineup, round_player: rp)
        end
      end

      it 'clones only max players' do
        service_call

        expect(target_tour.lineups.find_by(team_id: team.id).match_players.count).to eq(Lineup::MAX_PLAYERS)
      end
    end
  end
end

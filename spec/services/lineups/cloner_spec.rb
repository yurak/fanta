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

    context 'when previous lineup belongs to another league' do
      let(:another_league) { create(:league) }
      let(:team) { create(:team, league: another_league) }

      before do
        create(:lineup, team: team, tour: create(:tour, league: another_league))
      end

      it 'returns false' do
        expect(service_call).to be(false)
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
          tournament_round_ids = cloned_lineup.round_players.pluck(:tournament_round_id).uniq

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

    context 'when old lineup has more than max players' do
      before do
        old_tournament_round = create(:tournament_round, tournament: league.tournament)
        old_tour = create(:tour, league: league, tournament_round: old_tournament_round)
        old_lineup = create(:lineup, team: team, tour: old_tour)

        create_list(
          :match_player,
          Lineup::MAX_PLAYERS + 2,
          lineup: old_lineup,
          round_player: create(:round_player, tournament_round: old_tournament_round)
        )
      end

      it 'clones only max players' do
        service_call

        expect(target_tour.lineups.find_by(team_id: team.id).match_players.count).to eq(Lineup::MAX_PLAYERS)
      end
    end
  end
end

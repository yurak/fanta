# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Lineups::FantaCopier do
  subject(:service_call) { described_class.new(lineup).call }

  let(:user) { create(:user) }
  let(:tournament) { create(:fanta_tournament) }
  let(:tournament_round) { create(:tournament_round, tournament: tournament) }

  let(:source_league) { create(:active_league, tournament: tournament) }
  let(:target_league) { create(:active_league, tournament: tournament) }

  let(:source_team) { create(:team, user: user, league: source_league) }
  let(:target_team) { create(:team, user: user, league: target_league) }

  let(:source_tour) { create(:set_lineup_tour, league: source_league, tournament_round: tournament_round) }
  let(:target_tour) { create(:set_lineup_tour, league: target_league, tournament_round: tournament_round) }

  let(:lineup) { create(:lineup, :with_fanta_score_five, team: source_team, tour: source_tour) }

  before { lineup && target_team && target_tour }

  describe '#call' do
    context 'when tour is not fanta' do
      let(:mantra_league) { create(:league) }
      let(:mantra_tour) do
        create(:set_lineup_tour, league: mantra_league,
                                 tournament_round: create(:tournament_round, tournament: mantra_league.tournament))
      end
      let(:lineup) { create(:lineup, :with_fanta_score_five, team: create(:team, user: user, league: mantra_league), tour: mantra_tour) }

      it 'returns false' do
        expect(service_call).to be(false)
      end
    end

    context 'when user has one other fanta team in the same tournament' do
      it 'creates a lineup for the other league' do
        expect { service_call }.to change { target_tour.lineups.count }.by(1)
      end

      it 'copies match_players to the new lineup' do
        service_call
        expect(target_tour.lineups.first.match_players.count).to eq(lineup.match_players.count)
      end

      it 'sets creation_type to copied' do
        service_call
        expect(target_tour.lineups.first).to be_copied
      end

      it 'copies real_positions' do
        service_call
        source_positions = lineup.match_players.map(&:real_position).sort_by(&:to_s)
        target_positions = target_tour.lineups.first.match_players.map(&:real_position).sort_by(&:to_s)
        expect(target_positions).to eq(source_positions)
      end

      it 'reuses the same round_players' do
        service_call
        source_rp_ids = lineup.match_players.map(&:round_player_id).sort
        target_rp_ids = target_tour.lineups.first.match_players.map(&:round_player_id).sort
        expect(target_rp_ids).to eq(source_rp_ids)
      end

      it 'preserves main player order (slot assignment)' do
        service_call
        source_main_rp_ids = lineup.match_players.main.map(&:round_player_id)
        target_main_rp_ids = target_tour.lineups.first.match_players.main.map(&:round_player_id)
        expect(target_main_rp_ids).to eq(source_main_rp_ids)
      end

      it 'copies main players before bench players' do
        service_call
        target_lineup = target_tour.lineups.first
        main_max_id = target_lineup.match_players.main.maximum(:id)
        bench_min_id = target_lineup.match_players.subs_bench.minimum(:id)
        expect(main_max_id).to be < bench_min_id
      end
    end

    context 'when target tour already has a lineup' do
      before { create(:lineup, team: target_team, tour: target_tour) }

      it 'does not create another lineup' do
        expect { service_call }.not_to(change { target_tour.lineups.count })
      end
    end

    context 'when target tour is not open for lineup' do
      let(:target_tour) { create(:closed_tour, league: target_league, tournament_round: tournament_round) }

      it 'does not create a lineup' do
        expect { service_call }.not_to(change { target_tour.lineups.count })
      end
    end

    context 'when user has teams in multiple other fanta leagues' do
      let(:league3) { create(:active_league, tournament: tournament) }
      let(:team3) { create(:team, user: user, league: league3) }
      let(:tour3) { create(:set_lineup_tour, league: league3, tournament_round: tournament_round) }

      before { team3 && tour3 }

      it 'copies to all other leagues' do
        expect { service_call }.to change { target_tour.lineups.count + tour3.lineups.count }.by(2)
      end
    end

    context 'when user has a team in a different tournament' do
      let(:other_tournament) { create(:fanta_tournament) }
      let(:other_league) { create(:active_league, tournament: other_tournament) }
      let(:other_team) { create(:team, user: user, league: other_league) }
      let(:other_tour) do
        create(:set_lineup_tour, league: other_league,
                                 tournament_round: create(:tournament_round, tournament: other_tournament))
      end

      before { other_team && other_tour }

      it 'does not copy to the other tournament' do
        expect { service_call }.not_to(change { other_tour.lineups.count })
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers

require 'rails_helper'

RSpec.describe Tours::LineupGenerator do
  subject(:generator) { described_class.call(tour) }

  context 'with non-locked tour' do
    let(:tour) { create(:set_lineup_tour) }

    it 'does nothing' do
      expect { generator }.not_to change(Lineup, :count)
    end
  end

  context 'with locked fanta tour' do
    let(:tournament_round) { create(:tournament_round, tournament: create(:fanta_tournament)) }
    let(:tour) { create(:locked_tour, tournament_round: tournament_round) }

    it 'does nothing' do
      expect { generator }.not_to change(MatchPlayer, :count)
    end
  end

  context 'with locked mantra tour' do
    let(:tournament_round) { create(:tournament_round) }
    let(:tour) { create(:locked_tour, tournament_round: tournament_round) }

    it 'marks tour as lineups_generated' do
      expect { generator }.to change { tour.reload.lineups_generated }.from(false).to(true)
    end

    context 'when team has no lineup' do
      let(:team) { create(:team, league: tour.league) }

      before { create(:lineup, :with_match_players, tour: create(:closed_tour, league: tour.league), team: team) }

      it 'clones lineup from previous tour' do
        expect { generator }.to change(Lineup, :count).by(1)
      end
    end

    context 'when team has lineup but player is not in squad' do
      let(:team) { create(:team, league: tour.league) }
      let!(:lineup) { create(:lineup, :with_match_players, tour: tour, team: team) }

      before do
        create(:tournament_match, tournament_round: tournament_round)
        round_player = create(:round_player, tournament_round: tournament_round)
        create(:player_team, team: team, player: round_player.player)
      end

      it 'generates not_in_squad match_players' do
        expect { generator }.to change { lineup.match_players.not_in_lineup.count }.by(1)
      end

      it 'is idempotent on second run' do
        generator
        expect { described_class.call(tour) }.not_to change(MatchPlayer, :count)
      end
    end

    context 'when team has lineup with match players' do
      let(:team) { create(:team, league: tour.league) }
      let!(:lineup) { create(:lineup, :with_match_players, tour: tour, team: team) }

      it 'snapshots player positions on all match players' do
        generator
        lineup.match_players.reload.each do |mp|
          expect(mp.player_positions).to eq(mp.round_player.position_names.join('/'))
        end
      end
    end
  end
end

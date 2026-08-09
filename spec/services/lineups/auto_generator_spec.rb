RSpec.describe Lineups::AutoGenerator do
  describe '#call' do
    subject(:generate) { described_class.call(team, tour) }

    let(:tour) { create(:locked_tour) }
    let(:team) { create(:team, league: tour.league) }

    # 25 distinct players covering every line (the :with_players_by_pos factory
    # reuses the same player across slots, which is not representative here).
    def add_players(trait, count)
      count.times { create(:player_team, team: team, player: create(:player, trait)) }
    end

    context 'with a full squad' do
      before do
        add_players(:with_pos_por, 3)
        add_players(:with_pos_dc, 4)
        add_players(:with_pos_dd, 2)
        add_players(:with_pos_ds, 2)
        add_players(:with_pos_e, 2)
        add_players(:with_pos_m, 2)
        add_players(:with_pos_c, 3)
        add_players(:with_pos_w, 3)
        add_players(:with_pos_a, 2)
        add_players(:with_pos_pc, 2)
      end

      it { is_expected.to be(true) }

      it 'creates one lineup for the team' do
        expect { generate }.to change { tour.lineups.by_team(team.id).count }.by(1)
      end

      context 'with a generated lineup' do
        let(:lineup) { tour.lineups.by_team(team.id).first }

        before { generate }

        it 'assigns a formation' do
          expect(lineup.team_module).to be_present
        end

        it 'fills 11 main slots' do
          expect(lineup.match_players.main.count).to eq(11)
        end

        it 'puts a goalkeeper in the goalkeeper slot' do
          gk = lineup.match_players.main.find { |mp| mp.real_position == Position::GOALKEEPER }
          expect(gk.player.position_names).to include(Position::GOALKEEPER)
        end

        it 'fills the bench up to the squad size' do
          expect(lineup.match_players.count).to eq(lineup.players_count)
        end

        it 'has no duplicate players' do
          ids = lineup.match_players.map { |mp| mp.round_player.player_id }
          expect(ids).to eq(ids.uniq)
        end

        it 'marks the lineup as auto generated' do
          expect(lineup.creation_type).to eq('auto_cloned')
        end
      end

      context 'when the team already has a lineup for the tour' do
        before { create(:lineup, team: team, tour: tour) }

        it { is_expected.to be(false) }

        it 'creates no additional lineup' do
          expect { generate }.not_to change(Lineup, :count)
        end
      end
    end

    context 'when the team has no players' do
      it { is_expected.to be(false) }
    end
  end
end

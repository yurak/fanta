RSpec.describe Players::Query do
  subject(:result) { described_class.call(params) }

  describe '#call' do
    context 'without players' do
      let(:params) { {} }

      it { is_expected.to eq([]) }
    end

    context 'when players exist' do
      before { create_list(:player, 3) }

      context 'without params' do
        let(:params) { {} }

        it 'returns all players' do
          expect(result.count).to eq(3)
        end

        it 'sorts by total score descending by default' do
          player_high = create(:player, :with_scores)

          expect(result.first).to eq(player_high)
        end
      end

      # --- Filtering ---

      context 'with league_id' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, club: create(:club, tournament: league.tournament)) }
        let(:params) { { league_id: league.id } }

        it 'returns only players from that league tournament' do
          expect(result).to contain_exactly(player)
        end
      end

      context 'with tournament_id' do
        let(:tournament) { Tournament.last }
        let!(:players) { create_list(:player, 2, club: create(:club, tournament: tournament)) }
        let(:params) { { tournament_id: tournament.id } }

        it 'returns players from that tournament' do
          expect(result).to eq(players)
        end
      end

      context 'with club_id' do
        let!(:player_a) { create(:player, club: create(:club)) }
        let!(:player_b) { create(:player, club: create(:club)) }
        let(:params) { { club_id: [player_a.club_id, player_b.club_id] } }

        it 'returns players from those clubs' do
          expect(result).to contain_exactly(player_a, player_b)
        end
      end

      context 'with name' do
        before { create(:player, name: 'Ronaldo', club: create(:club)) }

        let!(:player) { create(:player, name: 'Romario', club: create(:club)) }
        let(:params) { { name: player.name } }

        it 'returns matching player' do
          expect(result).to contain_exactly(player)
        end

        it 'does not raise when default sort is applied' do
          expect { result.to_a }.not_to raise_error
        end
      end

      context 'with position' do
        let!(:player_dc) { create(:player, :with_pos_dc) }
        let(:params) { { position: %w[CB] } }

        before { create(:player, :with_pos_pc) }

        it 'returns players with that position' do
          expect(result).to contain_exactly(player_dc)
        end
      end

      context 'with multiple positions matching the same player' do
        let!(:player) { create(:player, :with_pos_w_a) }
        let(:params) { { position: %w[W FW] } }

        it 'returns the player only once' do
          expect(result.to_a).to eq([player])
        end
      end

      context 'with min app' do
        let!(:player) { create(:player, :with_scores) }
        let(:params) { { app: { min: 2 } } }

        it 'returns only players with enough appearances' do
          expect(result).to contain_exactly(player)
        end
      end

      context 'with max app' do
        let!(:player) { create(:player, :with_scores) }
        let(:params) { { app: { max: 2 } } }

        it 'excludes players with too many appearances' do
          expect(result).not_to include(player)
        end
      end

      context 'with min base_score' do
        let!(:player) { create(:player, :with_scores) }
        let(:params) { { base_score: { min: 6 } } }

        it 'returns only players above the threshold' do
          expect(result).to contain_exactly(player)
        end
      end

      context 'with max base_score' do
        let!(:player) { create(:player, :with_scores) }
        let(:params) { { base_score: { max: 2 } } }

        it 'excludes players above the threshold' do
          expect(result).not_to include(player)
        end
      end

      context 'with min total_score' do
        let!(:player) { create(:player, :with_scores) }
        let(:params) { { total_score: { min: 6 } } }

        it 'returns only players above the threshold' do
          expect(result).to contain_exactly(player)
        end
      end

      context 'with max total_score' do
        let!(:player) { create(:player, :with_scores) }
        let(:params) { { total_score: { max: 2 } } }

        it 'excludes players above the threshold' do
          expect(result).not_to include(player)
        end
      end

      context 'with min teams_count' do
        let!(:player) { create(:player, :with_team) }
        let(:params) { { teams_count: { min: 1 } } }

        it 'returns only players with enough teams' do
          expect(result).to contain_exactly(player)
        end
      end

      context 'with max teams_count' do
        let!(:player) { create(:player, :with_team) }
        let(:params) { { teams_count: { max: 0 } } }

        it 'excludes players above the threshold' do
          expect(result).not_to include(player)
        end
      end

      context 'with league_id and team_id' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, club: create(:club, tournament: league.tournament)) }
        let(:team) { create(:team, league: league) }
        let(:params) { { league_id: league.id, team_id: [team.id.to_s] } }

        before { create(:player_team, player: player, team: team) }

        it 'returns only players in that team' do
          expect(result).to contain_exactly(player)
        end
      end

      context 'with league_id and without_team' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let(:club) { create(:club, tournament: league.tournament) }
        let!(:player) { create(:player, club: club) }
        let(:params) { { league_id: league.id, without_team: true } }

        before do
          other = create(:player, club: create(:club, tournament: league.tournament))
          team = create(:team, league: league)
          create(:player_team, player: other, team: team)
        end

        it 'returns only players without a team' do
          expect(result).to contain_exactly(player)
        end

        it 'sorts by total score descending by default' do
          player_high = create(:player, :with_scores, club: club)

          expect(result.first).to eq(player_high)
        end

        context 'when a player has only old season stats' do
          before do
            create(:player_season_stat, player: player, club: club,
                                        season: Season.last, tournament: league.tournament,
                                        final_score: 9.0)
            create(:season)
          end

          it 'sorts by current season score' do
            player_current = create(:player, :with_scores, club: club)

            expect(result.first).to eq(player_current)
          end
        end
      end

      context 'with league_id and team_id and without_team' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let(:club) { create(:club, tournament: league.tournament) }
        let!(:player_in_team) { create(:player, club: club) }
        let!(:player_without_team) { create(:player, club: club) }
        let(:team) { create(:team, league: league) }
        let(:params) { { league_id: league.id, team_id: [team.id.to_s], without_team: true } }

        before { create(:player_team, player: player_in_team, team: team) }

        it 'returns both team players and players without a team' do
          expect(result).to contain_exactly(player_in_team, player_without_team)
        end
      end

      context 'with league_id and price range' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let(:club) { create(:club, tournament: league.tournament) }
        let!(:cheap_player) { create(:player, club: club) }
        let!(:expensive_player) { create(:player, club: club) }
        let(:team) { create(:team, league: league) }

        before do
          create(:player_team, player: cheap_player, team: team)
          create(:transfer, player: cheap_player, team: team, price: 10, status: :incoming)
          create(:player_team, player: expensive_player, team: team)
          create(:transfer, player: expensive_player, team: team, price: 50, status: :incoming)
        end

        context 'with min price' do
          let(:params) { { league_id: league.id, price: { min: 20 } } }

          it 'excludes players below the minimum price' do
            expect(result).to contain_exactly(expensive_player)
          end
        end

        context 'with max price' do
          let(:params) { { league_id: league.id, price: { max: 20 } } }

          it 'excludes players above the maximum price' do
            expect(result).to contain_exactly(cheap_player)
          end
        end

        context 'without league_id' do
          let(:params) { { price: { min: 20 } } }

          it 'ignores the price filter' do
            expect(result).to include(cheap_player, expensive_player)
          end
        end
      end

      # --- Ordering ---

      context 'with field: name' do
        before do
          create(:player, name: 'Alpha')
          create(:player, name: 'Zebra')
        end

        context 'with default direction (desc)' do
          let(:params) { { field: 'name' } }

          it 'sorts A to Z' do
            expect(result.map(&:name).index('Alpha')).to be < result.map(&:name).index('Zebra')
          end
        end

        context 'with asc direction' do
          let(:params) { { field: 'name', direction: 'asc' } }

          it 'sorts Z to A' do
            expect(result.map(&:name).index('Zebra')).to be < result.map(&:name).index('Alpha')
          end
        end
      end

      context 'with field: club' do
        before do
          create(:player, club: create(:club, name: 'Beta FC'))
          create(:player, club: create(:club, name: 'Alpha FC'))
        end

        context 'with default direction (desc)' do
          let(:params) { { field: 'club' } }

          it 'sorts clubs A to Z' do
            expect(result.map { |p| p.club.name }.index('Alpha FC')).to be < result.map { |p| p.club.name }.index('Beta FC')
          end
        end
      end

      context 'with field: appearances' do
        let!(:player_high) { create(:player, :with_scores) }

        before { create(:player) }

        context 'with default direction (desc)' do
          let(:params) { { field: 'appearances' } }

          it 'puts highest appearances first' do
            expect(result.first).to eq(player_high)
          end
        end

        context 'with asc direction' do
          let(:params) { { field: 'appearances', direction: 'asc' } }

          it 'puts highest appearances last' do
            expect(result.to_a.last).to eq(player_high)
          end
        end
      end

      context 'with field: base_score' do
        let!(:player_high) { create(:player, :with_scores) }

        before { create(:player) }

        context 'with default direction (desc)' do
          let(:params) { { field: 'base_score' } }

          it 'puts highest score first' do
            expect(result.first).to eq(player_high)
          end
        end

        context 'with asc direction' do
          let(:params) { { field: 'base_score', direction: 'asc' } }

          it 'puts highest score last' do
            expect(result.to_a.last).to eq(player_high)
          end
        end
      end

      # --- Filter + Order combined ---

      context 'with filtering and ordering combined' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player_a) { create(:player, name: 'Alpha', club: create(:club, tournament: league.tournament)) }
        let!(:player_z) { create(:player, name: 'Zebra', club: create(:club, tournament: league.tournament)) }
        let(:params) { { league_id: league.id, field: 'name' } }

        it 'applies both filter and order' do
          expect(result).to eq([player_a, player_z])
        end
      end
    end
  end
end

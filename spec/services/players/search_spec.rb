RSpec.describe Players::Search do
  describe '#call' do
    subject(:service) { described_class.new(params) }

    let(:params) { {} }

    context 'without players' do
      it { expect(service.call).to eq([]) }
    end

    context 'when players exists' do
      before do
        create_list(:player, 3)
      end

      context 'without params' do
        it 'returns all players' do
          expect(service.call.count).to eq(3)
        end
      end

      context 'with league_id' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, club: create(:club, tournament: league.tournament)) }
        let(:params) { { league_id: league.id } }

        it 'returns filtered players' do
          expect(service.call).to eq([player])
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(1)
        end
      end

      context 'with league_id and tournament_id' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, club: create(:club, tournament: league.tournament)) }
        let(:params) { { league_id: league.id, tournament_id: Tournament.first } }

        it 'returns filtered players' do
          expect(service.call).to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(1)
        end
      end

      context 'with tournament_id' do
        let(:tournament) { Tournament.last }
        let!(:players) { create_list(:player, 2, club: create(:club, tournament: tournament)) }
        let(:params) { { tournament_id: tournament.id } }

        it 'returns filtered players' do
          expect(service.call).to eq(players)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(2)
        end
      end

      context 'with multiple club_id' do
        let!(:player_one) { create(:player, club: create(:club)) }
        let!(:player_two) { create(:player, club: create(:club)) }
        let(:params) { { club_id: [player_one.club_id, player_two.club_id] } }

        it 'returns filtered players' do
          expect(service.call).to contain_exactly(player_one, player_two)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(2)
        end
      end

      context 'with name' do
        let(:player_one) { create(:player, name: 'Ronaldo', club: create(:club)) }
        let!(:player_two) { create(:player, name: 'Romario', club: create(:club)) }
        let(:params) { { name: player_two.name } }

        it 'returns filtered players' do
          expect(service.call).to contain_exactly(player_two)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(1)
        end
      end

      context 'with position' do
        let!(:player_one) { create(:player, :with_pos_dc) }
        let(:player_two) { create(:player, :with_pos_e) }
        let!(:player_three) { create(:player, :with_pos_dd_ds_e) }
        let(:params) { { position: %w[CB LB] } }

        it 'returns filtered players' do
          expect(service.call).to contain_exactly(player_one, player_three)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(2)
        end
      end

      context 'with name and position' do
        let(:player_one) { create(:player, :with_pos_dc, name: 'Nesta') }
        let(:player_two) { create(:player, :with_pos_e, name: 'Cafu') }
        let!(:player_three) { create(:player, :with_pos_dd_ds_e, name: 'Florenzi') }
        let(:params) { { position: %w[CB LB], name: player_three.name } }

        it 'returns filtered players' do
          expect(service.call).to contain_exactly(player_three)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(1)
        end
      end

      context 'with league_id and without_team' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, club: create(:club, tournament: league.tournament)) }
        let(:params) { { league_id: league.id, without_team: true } }

        before do
          player = create(:player, club: create(:club, tournament: league.tournament))
          team = create(:team, league: league)
          create(:player_team, player: player, team: team)
        end

        it 'returns filtered players' do
          expect(service.call).to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(1)
        end
      end

      context 'with without_team and without league_id' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, club: create(:club, tournament: league.tournament)) }
        let(:params) { { without_team: true } }

        before do
          player = create(:player, club: create(:club, tournament: league.tournament))
          team = create(:team, league: league)
          create(:player_team, player: player, team: team)
        end

        it 'returns all players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(5)
        end
      end

      context 'with team_id and without league_id' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, club: create(:club, tournament: league.tournament)) }
        let(:team) { create(:team, league: league) }
        let(:params) { { team_id: [team.id.to_s] } }

        before do
          create(:player_team, player: player, team: team)
        end

        it 'returns all players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(4)
        end
      end

      context 'with team_id and league_id' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, club: create(:club, tournament: league.tournament)) }
        let(:team) { create(:team, league: league) }
        let(:params) { { league_id: league.id, team_id: [team.id.to_s] } }

        before do
          create(:player_team, player: player, team: team)
        end

        it 'returns filtered players' do
          expect(service.call).to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(1)
        end
      end

      context 'with empty app' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores, club: create(:club, tournament: league.tournament)) }
        let(:team) { create(:team, league: league) }
        let(:params) { { app: {} } }

        before do
          create(:player_team, player: player, team: team)
        end

        it 'returns all players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(4)
        end
      end

      context 'with min app' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores, club: create(:club, tournament: league.tournament)) }
        let(:params) { { app: { min: 2 } } }

        it 'returns filtered players' do
          expect(service.call).to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(1)
        end
      end

      context 'with max app' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores, club: create(:club, tournament: league.tournament)) }
        let(:params) { { app: { max: 2 } } }

        it 'returns filtered players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(3)
        end
      end

      context 'with min and max app' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores, club: create(:club, tournament: league.tournament)) }
        let(:params) { { app: { min: 2, max: 2 } } }

        it 'returns filtered players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(0)
        end
      end

      context 'with empty base_score' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores, club: create(:club, tournament: league.tournament)) }
        let(:team) { create(:team, league: league) }
        let(:params) { { base_score: {} } }

        before do
          create(:player_team, player: player, team: team)
        end

        it 'returns all players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(4)
        end
      end

      context 'with min base_score' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores, club: create(:club, tournament: league.tournament)) }
        let(:params) { { base_score: { min: 6 } } }

        it 'returns filtered players' do
          expect(service.call).to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(1)
        end
      end

      context 'with max base_score' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores, club: create(:club, tournament: league.tournament)) }
        let(:params) { { base_score: { max: 2 } } }

        it 'returns filtered players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(3)
        end
      end

      context 'with min and max base_score' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores, club: create(:club, tournament: league.tournament)) }
        let(:params) { { base_score: { min: 2, max: 2 } } }

        it 'returns filtered players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(0)
        end
      end

      context 'with empty total_score' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores_n_bonuses, club: create(:club, tournament: league.tournament)) }
        let(:team) { create(:team, league: league) }
        let(:params) { { total_score: {} } }

        before do
          create(:player_team, player: player, team: team)
        end

        it 'returns all players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(4)
        end
      end

      context 'with min total_score' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores_n_bonuses, club: create(:club, tournament: league.tournament)) }
        let(:params) { { total_score: { min: 6 } } }

        it 'returns filtered players' do
          expect(service.call).to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(1)
        end
      end

      context 'with max total_score' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores_n_bonuses, club: create(:club, tournament: league.tournament)) }
        let(:params) { { total_score: { max: 2 } } }

        it 'returns filtered players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(3)
        end
      end

      context 'with min and max total_score' do
        let(:league) { create(:league, tournament: Tournament.last) }
        let!(:player) { create(:player, :with_scores_n_bonuses, club: create(:club, tournament: league.tournament)) }
        let(:params) { { total_score: { min: 2, max: 2 } } }

        it 'returns filtered players' do
          expect(service.call).not_to contain_exactly(player)
        end

        it 'returns correct number of players' do
          expect(service.call.count).to eq(0)
        end
      end
    end
  end
end

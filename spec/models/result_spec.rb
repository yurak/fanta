RSpec.describe Result do
  subject(:result) { create(:result) }

  describe 'Associations' do
    it { is_expected.to belong_to(:league) }
    it { is_expected.to belong_to(:team) }
    it { is_expected.to delegate_method(:lineups).to(:team) }
  end

  describe '#matches_played' do
    context 'without wins, draws and loses' do
      it 'returns zero' do
        expect(result.matches_played).to eq(0)
      end
    end

    context 'with wins, draws and loses' do
      let(:result) { create(:result, wins: 4, draws: 1, loses: 2) }

      it 'returns played matches count' do
        expect(result.matches_played).to eq(7)
      end
    end
  end

  describe '#goals_difference' do
    context 'without scored_goals and missed_goals' do
      it 'returns zero' do
        expect(result.goals_difference).to eq(0)
      end
    end

    context 'without scored_goals and with missed_goals' do
      let(:result) { create(:result, missed_goals: 8) }

      it 'returns goals difference' do
        expect(result.goals_difference).to eq(-8)
      end
    end

    context 'with scored_goals and without missed_goals' do
      let(:result) { create(:result, scored_goals: 8) }

      it 'returns goals difference' do
        expect(result.goals_difference).to eq(8)
      end
    end

    context 'with scored_goals and missed_goals' do
      let(:result) { create(:result, scored_goals: 13, missed_goals: 8) }

      it 'returns goals difference' do
        expect(result.goals_difference).to eq(5)
      end
    end
  end

  describe '#position' do
    context 'without opponents in league' do
      it 'returns one' do
        expect(result.position).to eq(1)
      end
    end

    context 'with opponents in league' do
      let(:result) { create(:result, :with_opponents, points: 22) }

      it 'returns team position' do
        expect(result.position).to eq(3)
      end
    end

    context 'when results with same points' do
      let(:result) { create(:result, :with_opponents, points: 27, scored_goals: 34, missed_goals: 23) }

      it 'returns team position' do
        expect(result.position).to eq(2)
      end
    end

    context 'when results with same points and goal difference' do
      let(:result) { create(:result, :with_opponents, points: 34, scored_goals: 55, missed_goals: 23) }

      it 'returns team position' do
        expect(result.position).to eq(1)
      end
    end
  end

  describe '#form' do
    context 'without closed lineups' do
      it 'returns empty array' do
        expect(result.form).to eq([])
      end
    end
  end

  describe '#league_best_lineup' do
    context 'without closed lineups' do
      it 'returns 0' do
        expect(result.league_best_lineup).to eq(0)
      end
    end

    context 'with closed lineups' do
      it 'returns lineup with best total_score' do
        create(:lineup, :with_team_and_score_six, team: result.team, tour: create(:closed_tour, league: result.league))
        lineup_two = create(:lineup, :with_team_and_score_seven, team: result.team, tour: create(:closed_tour, league: result.league))
        create(:lineup, :with_team_and_score_five, team: result.team, tour: create(:closed_tour, league: result.league))

        expect(result.league_best_lineup).to eq(lineup_two.total_score)
      end
    end
  end
end

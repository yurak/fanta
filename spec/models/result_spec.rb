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

  describe '#live_position' do
    context 'without opponents in league' do
      it 'returns one' do
        expect(result.live_position).to eq(1)
      end
    end

    context 'with opponents in league' do
      let(:result) { create(:result, :with_opponents, points: 22) }

      it 'returns team position' do
        expect(result.live_position).to eq(3)
      end
    end

    context 'when results with same points' do
      let(:result) { create(:result, :with_opponents, points: 27, scored_goals: 33) }

      it 'returns team position' do
        expect(result.live_position).to eq(3)
      end
    end

    context 'when results with same points and scored goals' do
      let(:result) { create(:result, :with_opponents, points: 27, scored_goals: 34, wins: 8) }

      it 'returns team position' do
        expect(result.live_position).to eq(2)
      end
    end

    context 'when results with same points, scored goals and wins' do
      let(:result) { create(:result, :with_opponents, points: 27, scored_goals: 34, wins: 7, total_score: 1100) }

      it 'returns team position' do
        expect(result.live_position).to eq(3)
      end
    end

    context 'when results with same points, scored goals, wins and total score' do
      let(:result) { create(:result, :with_opponents, points: 27, scored_goals: 34, wins: 7, total_score: 1200, missed_goals: 23) }

      it 'returns team position' do
        expect(result.live_position).to eq(2)
      end
    end

    context 'when results with same points, scored goals, wins, total score and goal difference' do
      let(:result) { create(:result, :with_opponents, points: 27, scored_goals: 34, wins: 7, total_score: 1200, missed_goals: 26) }

      it 'returns team position' do
        expect(result.live_position).to eq(2)
      end
    end
  end

  describe '#fanta_position' do
    context 'without opponents in league' do
      it 'returns one' do
        expect(result.fanta_position).to eq(1)
      end
    end

    context 'with opponents in league' do
      let(:result) { create(:result, :with_opponents, total_score: 1100) }

      it 'returns team position' do
        expect(result.fanta_position).to eq(3)
      end
    end

    context 'when results with same total_score' do
      let(:result) { create(:result, :with_opponents, total_score: 1200, points: 28) }

      it 'returns team position' do
        expect(result.fanta_position).to eq(2)
      end
    end

    context 'when results with same total_score and points' do
      let(:result) { create(:result, :with_opponents, total_score: 1500, points: 15, best_lineup: 99) }

      it 'returns team position' do
        expect(result.fanta_position).to eq(1)
      end
    end
  end

  describe '#promoted?' do
    context 'when league fanta' do
      let(:result) { create(:result, league: create(:league, :fanta_league)) }

      it 'returns false' do
        expect(result).not_to be_promoted
      end
    end

    context 'when league is mantra but not archived' do
      it 'returns false' do
        expect(result).not_to be_promoted
      end
    end

    context 'when league is mantra and archived' do
      let(:result) { create(:result, league: create(:archived_league)) }

      context 'without promotion teams number' do
        it 'returns false' do
          expect(result).not_to be_promoted
        end
      end

      context 'with promotion teams number and team outside promotion zone' do
        let(:result) { create(:result, position: 4, league: create(:archived_league, promotion: 3)) }

        it 'returns false' do
          expect(result).not_to be_promoted
        end
      end

      context 'with promotion teams number and team inside promotion zone' do
        let(:result) { create(:result, position: 2, league: create(:archived_league, promotion: 3)) }

        it 'returns true' do
          expect(result).to be_promoted
        end
      end
    end
  end

  describe '#relegated?' do
    context 'when league fanta' do
      let(:result) { create(:result, league: create(:league, :fanta_league)) }

      it 'returns false' do
        expect(result).not_to be_relegated
      end
    end

    context 'when league is mantra but not archived' do
      it 'returns false' do
        expect(result).not_to be_relegated
      end
    end

    context 'when league relegation parameter is not positive' do
      let(:result) { create(:result, league: create(:archived_league)) }

      it 'returns false' do
        expect(result).not_to be_relegated
      end
    end

    context 'when league is mantra, archived and relegation parameter is positive' do
      context 'with promotion teams number and team outside relegation zone' do
        let(:result) { create(:result, position: 4, league: create(:archived_league, :with_five_teams, relegation: 2)) }

        it 'returns false' do
          expect(result).not_to be_relegated
        end
      end

      context 'with promotion teams number and team inside promotion zone' do
        let(:result) { create(:result, position: 5, league: create(:archived_league, :with_five_teams, relegation: 2)) }

        it 'returns false' do
          expect(result).to be_relegated
        end
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

  describe '#lineup_pct' do
    let(:league) { create(:active_league) }
    let(:team) { create(:team, league: league) }
    let(:result) { create(:result, league: league, team: team) }

    context 'when no eligible tours exist' do
      it 'returns 0' do
        expect(result.lineup_pct).to eq(0)
      end
    end

    context 'when all lineups are manual' do
      before do
        tour = create(:closed_tour, league: league)
        create(:lineup, team: team, tour: tour, creation_type: :manual)
      end

      it 'returns 100' do
        expect(result.lineup_pct).to eq(100)
      end
    end

    context 'when half of lineups are manual' do
      before do
        tour1 = create(:closed_tour, league: league)
        tour2 = create(:closed_tour, league: league)
        create(:lineup, team: team, tour: tour1, creation_type: :manual)
        create(:lineup, team: team, tour: tour2, creation_type: :auto_cloned)
      end

      it 'returns 50' do
        expect(result.lineup_pct).to eq(50)
      end
    end

    context 'when lineups are copied' do
      before do
        tour = create(:closed_tour, league: league)
        create(:lineup, team: team, tour: tour, creation_type: :copied)
      end

      it 'counts copied as manual' do
        expect(result.lineup_pct).to eq(100)
      end
    end

    context 'when team has a lineup for an open (set_lineup) tour' do
      before do
        closed_tour = create(:closed_tour, league: league)
        open_tour = create(:tour, league: league, status: :set_lineup)
        create(:lineup, team: team, tour: closed_tour, creation_type: :manual)
        create(:lineup, team: team, tour: open_tour, creation_type: :manual)
      end

      it 'does not exceed 100%' do
        expect(result.lineup_pct).to eq(100)
      end
    end
  end

  describe '#crowned?' do
    context 'when title is false' do
      it 'returns false' do
        expect(result).not_to be_crowned
      end
    end

    context 'when title is true but no user_title' do
      let(:result) { create(:result, title: true) }

      it 'returns false' do
        expect(result).not_to be_crowned
      end
    end

    context 'when title is true and user_title exists' do
      let(:result) { create(:result, title: true) }

      before { create(:user_title, result: result, user: create(:user)) }

      it 'returns true' do
        expect(result.reload).to be_crowned
      end
    end
  end

  describe '#crownable?' do
    context 'when title is true but no user_title (legacy)' do
      let(:result) { create(:result, title: true) }

      it 'returns true' do
        expect(result).to be_crownable
      end
    end

    context 'when title is true and user_title exists' do
      let(:result) { create(:result, title: true) }

      before { create(:user_title, result: result, user: create(:user)) }

      it 'returns false' do
        expect(result.reload).not_to be_crownable
      end
    end

    context 'when result is not in first place' do
      let(:result) { create(:result, :with_opponents, points: 22) }

      it 'returns false' do
        expect(result).not_to be_crownable
      end
    end

    context 'when result is first place in an archived league' do
      let(:league) { create(:archived_league) }
      let(:result) { create(:result, league: league, points: 50) }

      before { create(:result, league: league, points: 20) }

      it 'returns true' do
        expect(result).to be_crownable
      end
    end

    context 'when result is first place in an active league' do
      let(:league) { create(:active_league) }
      let(:result) { create(:result, league: league, points: 30) }

      before { create(:result, league: league, points: 20) }

      context 'with enough points gap (gap > remaining_tours * 3)' do
        before { create_list(:tour, 3, league: league) }

        it 'returns true' do
          expect(result).to be_crownable
        end
      end

      context 'without enough points gap (gap <= remaining_tours * 3)' do
        before { create_list(:tour, 4, league: league) }

        it 'returns false' do
          expect(result).not_to be_crownable
        end
      end

      context 'with a postponed tour still remaining' do
        before do
          create_list(:tour, 3, league: league)
          create(:postponed_tour, league: league)
        end

        it 'counts postponed tours as still playable' do
          result.update!(points: 31)

          expect(result).not_to be_crownable
        end
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

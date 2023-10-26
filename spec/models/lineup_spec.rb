RSpec.describe Lineup do
  subject(:lineup) { create(:lineup, :with_match) }

  let(:lineup_team) { create(:lineup, :with_match_players) }
  let(:lineup_team_score_five) { create(:lineup, :with_team_and_score_five) }
  let(:lineup_team_score_seven) { create(:lineup, :with_team_and_score_seven) }
  let(:lineup_team_score_eight) { create(:lineup, :with_team_and_score_eight) }

  describe 'Associations' do
    it { is_expected.to belong_to(:team_module) }
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:tour) }
    it { is_expected.to have_many(:match_players).dependent(:destroy) }
    it { is_expected.to have_many(:round_players).through(:match_players) }
    it { is_expected.to accept_nested_attributes_for(:match_players) }
    it { is_expected.to accept_nested_attributes_for(:round_players) }
    it { is_expected.to delegate_method(:slots).to(:team_module) }
    it { is_expected.to delegate_method(:tournament_round).to(:tour) }
    it { is_expected.to delegate_method(:league).to(:team) }
  end

  describe '#total_score' do
    context 'when scores are too small for defense bonus' do
      it 'returns sum of players scores' do
        expect(lineup_team_score_five.total_score).to eq(55)
      end
    end

    context 'when scores are sufficient for defense bonus' do
      it 'returns sum of players scores defense bonus' do
        expect(lineup_team_score_seven.total_score).to eq(82)
      end
    end
  end

  describe '#current_score' do
    context 'when scores are too small for defense bonus' do
      it 'returns sum of players scores' do
        expect(lineup_team_score_five.current_score).to eq(55)
      end
    end

    context 'when scores are sufficient for defense bonus' do
      it 'returns sum of players scores defense bonus' do
        expect(lineup_team_score_seven.current_score).to eq(82)
      end
    end
  end

  describe '#defence_bonus' do
    context 'when league with default bonus range and small scores' do
      it 'returns zero' do
        expect(lineup_team_score_five.defence_bonus).to eq(0)
      end
    end

    context 'when league with default bonus range and middle scores' do
      it 'returns minimal bonus' do
        lineup_team_score_six = create(:lineup, :with_team_and_score_six)

        expect(lineup_team_score_six.defence_bonus).to eq(1)
      end
    end

    context 'when league with default bonus range and large scores' do
      it 'returns maximum bonus' do
        expect(lineup_team_score_seven.defence_bonus).to eq(5)
      end
    end

    context 'when league with custom bonus range and small scores' do
      let(:lineup_team_score_six_custom) { create(:lineup, :with_team_and_score_six, :league_with_custom_bonus) }

      it 'returns zero' do
        expect(lineup_team_score_six_custom.defence_bonus).to eq(0)
      end
    end

    context 'when league with custom bonus range and middle scores' do
      let(:lineup_team_score_seven_custom) { create(:lineup, :with_team_and_score_seven, :league_with_custom_bonus) }

      it 'returns minimal bonus' do
        expect(lineup_team_score_seven_custom.defence_bonus).to eq(1)
      end
    end

    context 'when league with custom bonus range and large scores' do
      let(:lineup_team_score_eight_custom) { create(:lineup, :with_team_and_score_eight, :league_with_custom_bonus) }

      it 'returns maximum bonus' do
        expect(lineup_team_score_eight_custom.defence_bonus).to eq(5)
      end
    end
  end

  describe '#goals' do
    context 'when total_score less than minimum' do
      it 'returns zero' do
        expect(lineup_team_score_five.goals).to eq(0)
      end
    end

    context 'when total_score more than minimum' do
      it 'returns goals number' do
        expect(lineup_team_score_seven.goals).to eq(2)
      end
    end

    context 'with lineup final_goals' do
      let(:lineup_team) { create(:lineup, :with_match_players, final_goals: 3) }

      it 'returns final_goals' do
        expect(lineup_team.goals).to eq(3)
      end
    end
  end

  describe '#live_goals' do
    context 'when total_score less than minimum' do
      it 'returns zero' do
        expect(lineup_team_score_five.live_goals).to eq(0)
      end
    end

    context 'when total_score more than minimum' do
      it 'returns goals number' do
        expect(lineup_team_score_seven.live_goals).to eq(2)
      end
    end

    context 'with lineup final_goals' do
      let(:lineup_team) { create(:lineup, :with_match_players, final_goals: 3) }

      it 'returns live goals' do
        expect(lineup_team.live_goals).to eq(0)
      end
    end
  end

  describe '#match' do
    it 'returns lineup match' do
      expect(lineup.match.class).to eq(Match)
    end
  end

  describe '#result' do
    context 'when opponent has better result' do
      let(:lineup_with_opponent) { create(:lineup, :with_team_and_score_six, :with_match_and_opponent_lineup) }

      it 'returns L' do
        expect(lineup_with_opponent.result).to eq('L')
      end
    end

    context 'when opponent has the same result' do
      let(:lineup_with_opponent) { create(:lineup, :with_team_and_score_seven, :with_match_and_opponent_lineup) }

      it 'returns D' do
        expect(lineup_with_opponent.result).to eq('D')
      end
    end

    context 'when opponent has worst result' do
      let(:lineup_with_opponent) { create(:lineup, :with_team_and_score_eight, :with_match_and_opponent_lineup) }

      it 'returns W' do
        expect(lineup_with_opponent.result).to eq('W')
      end
    end
  end

  describe '#completed?' do
    context 'when less than 11 main players have score' do
      it 'returns false' do
        expect(lineup_team.completed?).to be(false)
      end
    end

    context 'when all 11 main players have score' do
      it 'returns true' do
        expect(lineup_team_score_seven.completed?).to be(true)
      end
    end
  end

  describe '#mp_with_score' do
    it 'returns number of main match players with score' do
      expect(lineup_team_score_seven.mp_with_score).to eq(11)
    end
  end

  describe '#opponent' do
    context 'when lineup of host team' do
      it 'returns guest team' do
        opponent = lineup.match.guest
        create(:lineup, tour: lineup.tour, team: opponent)

        expect(lineup.opponent).to eq(opponent)
      end
    end

    context 'when lineup of guest team' do
      it 'returns host team' do
        match = create(:match, guest: lineup_team.team, tour: lineup_team.tour)
        create(:lineup, tour: lineup_team.tour, team: match.host)

        expect(lineup_team.opponent).to eq(match.host)
      end
    end
  end

  describe '#match_result' do
    context 'when lineup of host team' do
      it 'returns result' do
        match = create(:match, host: lineup_team_score_seven.team, tour: lineup_team_score_seven.tour)
        create(:lineup, :with_team_and_score_seven, tour: lineup_team_score_eight.tour, team: match.guest)

        expect(lineup_team_score_seven.match_result).to eq('2-0')
      end
    end

    context 'when lineup of guest team' do
      it 'returns result' do
        match = create(:match, guest: lineup_team_score_seven.team, tour: lineup_team_score_seven.tour)
        create(:lineup, :with_team_and_score_eight, tour: lineup_team_score_seven.tour, team: match.host)

        expect(lineup_team_score_seven.match_result).to eq('2-4')
      end
    end
  end

  describe '#players_count' do
    context 'when mantra tour' do
      it { expect(lineup.players_count).to eq(20) }
    end

    context 'when national tour' do
      before do
        create(:national_match, tournament_round: lineup.tour.tournament_round)
      end

      it { expect(lineup.players_count).to eq(16) }
    end
  end
end

RSpec.describe TournamentRound do
  subject(:tournament_round) { create(:tournament_round) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to belong_to(:season) }
    it { is_expected.to have_many(:national_matches).dependent(:destroy) }
    it { is_expected.to have_many(:round_players).dependent(:destroy) }
    it { is_expected.to have_many(:tournament_matches).dependent(:destroy) }
    it { is_expected.to have_many(:tours).dependent(:destroy) }
  end

  describe '#eurocup_players' do
    context 'when tournament is not eurocup' do
      it 'returns empty array' do
        expect(tournament_round.eurocup_players).to eq([])
      end
    end

    context 'when tournament is eurocup' do
      let(:tournament_round) { create(:tournament_round, :with_eurocup_tournament) }
      let(:club) { create(:club, :with_players_by_pos) }

      it 'returns round players which played at this round' do
        create(:tournament_match, tournament_round: tournament_round, host_club: club)
        round_players = club.players.map { |player| create(:round_player, :with_score_six, player: player) }

        expect(tournament_round.eurocup_players).to eq(round_players)
      end
    end
  end

  describe '#clubs_ids' do
    context 'without tournament matches' do
      it 'returns empty array' do
        expect(tournament_round.clubs_ids).to eq([])
      end
    end

    context 'with tournament matches' do
      let!(:tournament_match) { create(:tournament_match, tournament_round: tournament_round) }

      it 'returns array with clubs ids' do
        expect(tournament_round.clubs_ids).to eq([tournament_match.host_club_id, tournament_match.guest_club_id])
      end
    end
  end

  describe '#finished?' do
    context 'without tournament matches' do
      it 'returns false' do
        expect(tournament_round.finished?).to be(false)
      end
    end

    context 'with tournament matches without score' do
      let(:tournament_round) { create(:tournament_round, :with_initial_matches) }

      it 'returns false' do
        expect(tournament_round.finished?).to be(false)
      end
    end

    context 'with tournament matches with score' do
      let(:tournament_round) { create(:tournament_round, :with_finished_matches) }

      it 'returns true' do
        expect(tournament_round.finished?).to be(true)
      end
    end
  end

  describe '#time_to_deadline' do
    context 'without deadline' do
      let(:tournament_round) { create(:tournament_round, deadline: nil) }

      it 'returns empty string' do
        expect(tournament_round.time_to_deadline).to eq('')
      end
    end

    context 'with deadline' do
      let(:tournament_round) { create(:tournament_round, deadline: 2.days.ago) }

      it 'returns hash with time difference' do
        expect(tournament_round.time_to_deadline[:days]).to eq(2)
      end
    end
  end

  describe '#closing_time' do
    context 'without moderated_at' do
      it 'returns тшд' do
        expect(tournament_round.closing_time).to be_nil
      end
    end

    context 'with moderated_at' do
      let(:tournament_round) { create(:tournament_round, moderated_at: 'October 26, 2025 22:00') }

      it 'returns closing time' do
        expect(tournament_round.closing_time).to eq('October 27, 2025 16:00')
      end
    end
  end

  describe '#best_lineups' do
    let(:tour) { create(:tour, tournament_round: tournament_round) }

    context 'without lineups' do
      it 'returns empty array' do
        expect(tournament_round.best_lineups).to eq([])
      end
    end

    context 'when all lineups have zero final_score' do
      before do
        create(:lineup, tour: tour, final_score: 0)
        create(:lineup, tour: tour, final_score: 0)
      end

      it 'returns empty array' do
        expect(tournament_round.best_lineups).to eq([])
      end
    end

    context 'when lineups have different positive final scores' do
      let!(:lineup_high) { create(:lineup, tour: tour, final_score: 100) }

      before { create(:lineup, tour: tour, final_score: 50) }

      it 'returns lineup with highest score' do
        expect(tournament_round.best_lineups).to eq([lineup_high])
      end
    end

    context 'when multiple lineups have the same highest final score' do
      let!(:lineup_one) { create(:lineup, tour: tour, final_score: 100) }
      let!(:lineup_two) { create(:lineup, tour: tour, final_score: 100) }

      before { create(:lineup, tour: tour, final_score: 50) }

      it 'returns all lineups with the highest score' do
        expect(tournament_round.best_lineups).to contain_exactly(lineup_one, lineup_two)
      end
    end
  end

  describe '#worst_lineups' do
    let(:tour) { create(:tour, tournament_round: tournament_round) }

    context 'without lineups' do
      it 'returns empty array' do
        expect(tournament_round.worst_lineups).to eq([])
      end
    end

    context 'when all lineups have zero final_score' do
      before do
        create(:lineup, tour: tour, final_score: 0)
        create(:lineup, tour: tour, final_score: 0)
      end

      it 'returns empty array' do
        expect(tournament_round.worst_lineups).to eq([])
      end
    end

    context 'when lineups have different positive final scores' do
      let!(:lineup_low) { create(:lineup, tour: tour, final_score: 50) }

      before { create(:lineup, tour: tour, final_score: 100) }

      it 'returns lineup with lowest positive score' do
        expect(tournament_round.worst_lineups).to eq([lineup_low])
      end
    end

    context 'when multiple lineups have the same minimum positive score' do
      let!(:lineup_one) { create(:lineup, tour: tour, final_score: 50) }
      let!(:lineup_two) { create(:lineup, tour: tour, final_score: 50) }

      before { create(:lineup, tour: tour, final_score: 100) }

      it 'returns all lineups with the lowest score' do
        expect(tournament_round.worst_lineups).to contain_exactly(lineup_one, lineup_two)
      end
    end
  end

  describe '#best_bench' do
    let(:tour) { create(:tour, tournament_round: tournament_round) }

    context 'without lineups' do
      it 'returns nil' do
        expect(tournament_round.best_bench).to be_nil
      end
    end

    context 'with lineups having different bench averages' do
      let!(:lineup_low) { create(:lineup, tour: tour) }
      let!(:lineup_high) { create(:lineup, tour: tour) }

      before do
        create(:match_player, :with_score, lineup: lineup_low)
        create(:match_player, lineup: lineup_high, round_player: create(:round_player, :with_score_seven))
      end

      it 'returns lineup with highest average bench score' do
        expect(tournament_round.best_bench).to eq(lineup_high)
      end
    end
  end
end

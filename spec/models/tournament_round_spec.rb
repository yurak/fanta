RSpec.describe TournamentRound, type: :model do
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
        round_players = []
        club.players.each { |player| round_players << create(:round_player, :with_score_six, player: player) }

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
end

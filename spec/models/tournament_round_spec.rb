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
end

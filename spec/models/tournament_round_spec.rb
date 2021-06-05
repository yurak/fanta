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
end

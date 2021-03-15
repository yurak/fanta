RSpec.describe TournamentMatch, type: :model do
  subject(:tournament_match) { create(:tournament_match) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament_round) }
    it { is_expected.to belong_to(:host_club).class_name('Club') }
    it { is_expected.to belong_to(:guest_club).class_name('Club') }
  end
end

RSpec.describe NationalMatch, type: :model do
  subject(:national_match) { create(:national_match) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament_round) }
    it { is_expected.to belong_to(:host_team).class_name('NationalTeam') }
    it { is_expected.to belong_to(:guest_team).class_name('NationalTeam') }
  end
end

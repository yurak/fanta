RSpec.describe NationalTeam, type: :model do
  subject(:national_team) { create(:national_team) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to have_many(:players).dependent(:destroy) }

    it {
      expect(national_team).to have_many(:host_national_matches).class_name('NationalMatch')
                                                                .with_foreign_key('host_team_id')
                                                                .dependent(:destroy).inverse_of(:host_team)
    }

    it {
      expect(national_team).to have_many(:guest_national_matches).class_name('NationalMatch')
                                                                 .with_foreign_key('guest_team_id')
                                                                 .dependent(:destroy).inverse_of(:guest_team)
    }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of :name }
    it { is_expected.to validate_presence_of :code }
    it { is_expected.to validate_uniqueness_of :code }
  end
end

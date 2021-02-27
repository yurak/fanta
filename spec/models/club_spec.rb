RSpec.describe Club, type: :model do
  let(:club) { create(:club, name: 'FC Karpaty Lviv') }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to have_many(:players).dependent(:destroy) }

    it {
      expect(club).to have_many(:host_tournament_matches).class_name('TournamentMatch').with_foreign_key('host_club_id')
                                                         .dependent(:destroy).inverse_of(:host_club)
    }

    it {
      expect(club).to have_many(:guest_tournament_matches).class_name('TournamentMatch').with_foreign_key('guest_club_id')
                                                          .dependent(:destroy).inverse_of(:guest_club)
    }
  end

  describe 'Validations' do
    it { is_expected.to validate_uniqueness_of :name }
    it { is_expected.to validate_uniqueness_of :code }

    it { is_expected.to define_enum_for(:status).with_values(%i[active archived]) }
  end

  describe '#path_name' do
    context 'when name contains spaces' do
      it 'returns path name' do
        expect(club.path_name).to eq('fc_karpaty_lviv')
      end
    end
  end

  describe '#logo_path' do
    context 'when name contains spaces' do
      it 'returns logo path' do
        expect(club.logo_path).to eq('clubs/fc_karpaty_lviv.png')
      end
    end
  end

  describe '#opponent_by_round' do
    let(:tournament_round) { create(:tournament_round) }
    let(:club2) { create(:club, name: 'AC Milan') }

    context 'when club is host of match' do
      it 'returns opponent club' do
        create(:tournament_match, tournament_round: tournament_round, host_club: club, guest_club: club2)

        expect(club.opponent_by_round(tournament_round)).to eq(club2)
      end
    end

    context 'when club is guest of match' do
      it 'returns opponent club' do
        create(:tournament_match, tournament_round: tournament_round, host_club: club2, guest_club: club)

        expect(club.opponent_by_round(tournament_round)).to eq(club2)
      end
    end
  end
end

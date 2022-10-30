RSpec.describe NationalTeam do
  subject(:national_team) { create(:national_team) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to have_many(:players).dependent(:nullify) }

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

    it { is_expected.to define_enum_for(:status).with_values(%i[active archived]) }
  end

  describe '#opponent_by_round' do
    let(:tournament_round) { create(:tournament_round) }
    let(:national_team2) { create(:national_team, name: 'AC Milan') }

    context 'when national_team is host of match' do
      it 'returns opponent national_team' do
        create(:national_match, tournament_round: tournament_round, host_team: national_team, guest_team: national_team2)

        expect(national_team.opponent_by_round(tournament_round)).to eq(national_team2)
      end
    end

    context 'when national_team is guest of match' do
      it 'returns opponent national_team' do
        create(:national_match, tournament_round: tournament_round, host_team: national_team2, guest_team: national_team)

        expect(national_team.opponent_by_round(tournament_round)).to eq(national_team2)
      end
    end
  end

  describe '#matches' do
    let(:tournament_round) { create(:tournament_round, tournament: national_team.tournament) }

    context 'without national matches' do
      it 'returns empty array' do
        expect(national_team.matches).to eq([])
      end
    end

    context 'with host national matches' do
      it 'returns team national matches' do
        matches = create_list(:national_match, 3, host_team: national_team, tournament_round: tournament_round)

        expect(national_team.matches).to eq(matches)
      end
    end

    context 'with guest national matches' do
      it 'returns team national matches' do
        matches = create_list(:national_match, 2, guest_team: national_team, tournament_round: tournament_round)

        expect(national_team.matches).to eq(matches)
      end
    end
  end
end

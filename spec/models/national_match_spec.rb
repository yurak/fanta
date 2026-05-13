RSpec.describe NationalMatch do
  subject(:national_match) { create(:national_match) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament_round) }
    it { is_expected.to belong_to(:host_team).class_name('NationalTeam') }
    it { is_expected.to belong_to(:guest_team).class_name('NationalTeam') }
  end

  describe '.by_team' do
    let(:team) { create(:national_team) }
    let!(:host_match) { create(:national_match, host_team: team) }
    let!(:guest_match) { create(:national_match, guest_team: team) }

    before do
      create(:national_match)
    end

    it 'returns matches where team is host or guest' do
      expect(described_class.by_team(team.id)).to contain_exactly(host_match, guest_match)
    end
  end

  describe '.by_t_round' do
    let(:tournament_round) { create(:tournament_round) }
    let!(:matched_match) { create(:national_match, tournament_round: tournament_round) }

    before do
      create(:national_match)
    end

    it 'returns matches for tournament round' do
      expect(described_class.by_t_round(tournament_round.id)).to eq([matched_match])
    end
  end
end

RSpec.describe TournamentMatch do
  subject(:tournament_match) { create(:tournament_match) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament_round) }
    it { is_expected.to belong_to(:host_club).class_name('Club') }
    it { is_expected.to belong_to(:guest_club).class_name('Club') }
  end

  describe '.by_club' do
    let(:club) { create(:club) }
    let!(:host_match) { create(:tournament_match, host_club: club) }
    let!(:guest_match) { create(:tournament_match, guest_club: club) }

    before do
      create(:tournament_match)
    end

    it 'returns matches where club is host or guest' do
      expect(described_class.by_club(club.id)).to contain_exactly(host_match, guest_match)
    end
  end

  describe '.by_club_and_t_round' do
    let(:club) { create(:club) }
    let(:tournament_round) { create(:tournament_round) }
    let!(:matched_match) { create(:tournament_match, host_club: club, tournament_round: tournament_round) }

    before do
      create(:tournament_match, host_club: club)
    end

    it 'returns matches for club and tournament round' do
      expect(described_class.by_club_and_t_round(club.id, tournament_round.id)).to eq([matched_match])
    end
  end

  describe '#utc_datetime' do
    context 'when date and time are present' do
      subject(:match) { create(:tournament_match, date: 'JUN 15, 2026', time: '19:00') }

      it 'returns a DateTime in UTC' do
        expect(match.utc_datetime).to eq(DateTime.parse('2026-06-15 19:00:00 UTC'))
      end

      it 'returns UTC offset' do
        expect(match.utc_datetime.utc_offset).to eq(0)
      end
    end

    context 'when date is blank' do
      subject(:match) { create(:tournament_match, date: '', time: '19:00') }

      it { expect(match.utc_datetime).to be_nil }
    end

    context 'when time is blank' do
      subject(:match) { create(:tournament_match, date: 'JUN 15, 2026', time: '') }

      it { expect(match.utc_datetime).to be_nil }
    end
  end

  describe '#missed_players_data' do
    it 'serializes JSON data' do
      tournament_match.update!(missed_players_data: { 'players' => [1, 2] })

      expect(tournament_match.reload.missed_players_data).to eq('players' => [1, 2])
    end
  end
end

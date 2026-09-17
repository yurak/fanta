RSpec.describe ToursHelper do
  describe '#time_to_deadline(time_hash)' do
    let(:time_hash) { nil }

    context 'without time_hash' do
      it 'returns empty array' do
        expect(helper.time_to_deadline(time_hash)).to eq('')
      end
    end

    context 'with time_hash' do
      let(:time_hash) { { days: 3, minutes: 45 } }

      it 'returns empty array' do
        expect(helper.time_to_deadline(time_hash)).to eq('3d 45m left')
      end
    end
  end

  describe '#round_opponents' do
    subject(:opponents) { helper.round_opponents(round) }

    let(:round) { create(:tournament_round) }
    let(:host) { create(:club) }
    let(:guest) { create(:club) }

    before { create(:tournament_match, tournament_round: round, host_club: host, guest_club: guest) }

    it 'maps the home club to its visitor' do
      expect(opponents[host.id]).to eq(guest)
    end

    it 'maps the away club to its host' do
      expect(opponents[guest.id]).to eq(host)
    end

    it 'leaves out a club that does not play this round' do
      expect(opponents[create(:club).id]).to be_nil
    end
  end
end

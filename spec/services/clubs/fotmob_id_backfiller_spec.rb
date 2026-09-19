require 'rails_helper'

RSpec.describe Clubs::FotmobIdBackfiller do
  subject(:backfill) { described_class.call(tournament) }

  let(:tournament) { create(:tournament, source_id: 441) }
  let(:round) { create(:tournament_round, tournament: tournament) }
  let(:host) { create(:club, tournament: tournament) }
  let(:guest) { create(:club, tournament: tournament) }
  let(:entries) do
    [{ source_match_id: '5909352', home_fotmob_id: 9728, away_fotmob_id: 8688 }]
  end

  before { allow(TournamentRounds::FotmobCalendarParser).to receive(:call).and_return(entries) }

  context 'when source_match_id is the FotMob id' do
    before do
      create(:tournament_match, tournament_round: round, host_club: host, guest_club: guest,
                                source_match_id: '5909352', page_url: '/matches/a-vs-b/x#5909352')
    end

    it 'fills both sides' do
      backfill

      expect([host.reload.fotmob_id, guest.reload.fotmob_id]).to eq([9728, 8688])
    end

    it 'returns how many clubs it touched' do
      expect(backfill).to eq(2)
    end

    it 'is idempotent' do
      backfill

      expect(described_class.call(tournament)).to eq(0)
    end
  end

  # Ukraine imports its calendar from SofaScore, so source_match_id is a SofaScore id there and the
  # FotMob id only survives in the page_url fragment.
  context 'when source_match_id belongs to another provider' do
    before do
      create(:tournament_match, tournament_round: round, host_club: host, guest_club: guest,
                                source_match_id: '16413140', page_url: '/matches/a-vs-b/x#5909352')
    end

    it 'still joins through the id in page_url' do
      backfill

      expect(host.reload.fotmob_id).to eq(9728)
    end
  end

  context 'when another club already holds that FotMob id' do
    before do
      create(:club, tournament: tournament, fotmob_id: 9728)
      create(:tournament_match, tournament_round: round, host_club: host, guest_club: guest,
                                source_match_id: '5909352', page_url: '/matches/a-vs-b/x#5909352')
    end

    it 'leaves the duplicate alone rather than failing the unique index' do
      backfill

      expect(host.reload.fotmob_id).to be_nil
    end
  end
end

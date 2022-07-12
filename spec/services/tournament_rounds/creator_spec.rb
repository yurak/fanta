RSpec.describe TournamentRounds::Creator do
  describe '#call' do
    subject(:creator) { described_class.new(tournament_id, season_id, count) }

    let(:tournament) { Tournament.last }
    let(:tournament_id) { tournament.id }
    let(:season) { create(:season) }
    let(:season_id) { season.id }
    let(:count) { 10 }

    context 'with invalid tournament id' do
      let(:tournament_id) { 'invalid' }

      it { expect(creator.call).to be(false) }
    end

    context 'with invalid season id' do
      let(:season_id) { 'invalid' }

      it { expect(creator.call).to be(false) }
    end

    context 'without count param' do
      subject(:creator) { described_class.new(tournament_id, season_id) }

      before do
        creator.call
      end

      it { expect(TournamentRound.where(tournament: tournament, season: season).count).to eq(38) }
    end

    context 'with count param' do
      before do
        creator.call
      end

      it { expect(TournamentRound.where(tournament: tournament, season: season).count).to eq(10) }
    end
  end
end

RSpec.describe Audit::CsvWriter do
  describe '#call' do
    subject(:writer) { described_class.new(tournament_match, players) }

    let(:tournament_match) { create(:tournament_match) }
    let(:players) { { 'player name' => { played_minutes: 67, rating: '6.9' }, 'player name_two' => { played_minutes: 90, rating: '7.5' } } }

    context 'with player hashes' do
      it { expect(writer.call).to eq(players) }
    end

    context 'with blank player hashes' do
      let(:players) { {} }

      it { expect(writer.call).to eq({}) }
    end

    context 'with national match' do
      let(:tournament) { create(:tournament, :with_national_teams) }
      let(:tournament_match) { create(:national_match, tournament_round: create(:tournament_round, tournament: tournament)) }

      it { expect(writer.call).to eq(players) }
    end
  end
end

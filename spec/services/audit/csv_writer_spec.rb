RSpec.describe Audit::CsvWriter do
  describe '#call' do
    subject(:writer) { described_class.new(tournament_match, host_players, guest_players) }

    let(:tournament_match) { create(:tournament_match) }
    let(:host_players) { { 'player name' => { played_minutes: 67, rating: '6.9' } } }
    let(:guest_players) { { 'player name' => { played_minutes: 90, rating: '7.5' } } }

    context 'with player hashes' do
      it { expect(writer.call).to eq(guest_players) }
    end

    context 'with blank player hashes' do
      let(:host_players) { {} }
      let(:guest_players) { {} }

      it { expect(writer.call).to eq(nil) }
    end

    context 'with national match' do
      let(:tournament) { create(:tournament, :with_national_teams) }
      let(:tournament_match) { create(:national_match, tournament_round: create(:tournament_round, tournament: tournament)) }

      it { expect(writer.call).to eq(guest_players) }
    end
  end
end

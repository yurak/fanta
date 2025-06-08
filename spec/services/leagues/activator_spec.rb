RSpec.describe Leagues::Activator do
  describe '#call' do
    subject(:activator) { described_class.new(league_id) }

    let(:league) { create(:league) }
    let(:league_id) { league.id }

    context 'with blank league_id' do
      let(:league_id) { nil }

      it { expect(activator.call).to be(false) }
    end

    context 'when league is active' do
      let(:league) { create(:active_league) }
      let(:league_id) { league.id }

      it { expect(activator.call).to be(false) }
    end

    context 'when league is archived' do
      let(:league) { create(:archived_league) }

      it { expect(activator.call).to be(false) }
    end

    context 'when league is initial and without teams' do
      it { expect(activator.call).to be(false) }
    end

    context 'when league is initial, with teams and base configs' do
      let!(:league) { create(:league, :with_five_teams) }

      before do
        create(:tournament_round, number: 1, tournament: league.tournament, season: league.season)
        create(:tournament_round, number: 2, tournament: league.tournament, season: league.season)
        create(:tournament_round, number: 3, tournament: league.tournament, season: league.season)

        activator.call
      end

      it 'updates teams transfer_slots' do
        expect(league.teams.reload.first.transfer_slots).to eq(20)
      end

      it 'creates auctions' do
        expect(league.auctions.count).to eq(5)
      end

      it 'creates results' do
        expect(league.results.count).to eq(5)
      end

      it 'creates tours' do
        expect(league.tours.count).to eq(3)
      end
    end

    context 'when league is initial, with teams and custom configs' do
      let!(:league) { create(:league, :with_five_teams, tour_difference: 1, auction_number: 3) }

      before do
        create(:tournament_round, number: 1, tournament: league.tournament, season: league.season)
        create(:tournament_round, number: 2, tournament: league.tournament, season: league.season)
        create(:tournament_round, number: 3, tournament: league.tournament, season: league.season)
        activator.call
      end

      it 'updates teams transfer_slots' do
        expect(league.teams.reload.first.transfer_slots).to eq(12)
      end

      it 'creates auctions' do
        expect(league.auctions.count).to eq(3)
      end

      it 'creates results' do
        expect(league.results.count).to eq(5)
      end

      it 'creates tours' do
        expect(league.tours.count).to eq(2)
      end
    end
  end
end

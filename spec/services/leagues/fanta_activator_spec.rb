RSpec.describe Leagues::FantaActivator do
  describe '#call' do
    subject(:activator) { described_class.new(league_id) }

    let(:tournament) { create(:fanta_tournament) }
    let(:league) { create(:league, tournament: tournament) }
    let(:league_id) { league.id }

    context 'with blank league_id' do
      let(:league_id) { nil }

      it { expect(activator.call).to be(false) }
    end

    context 'when league is active' do
      let(:league) { create(:active_league, tournament: tournament) }

      it { expect(activator.call).to be(false) }
    end

    context 'when league is archived' do
      let(:league) { create(:archived_league, tournament: tournament) }

      it { expect(activator.call).to be(false) }
    end

    context 'when league is initial and without teams' do
      before do
        create(:tournament_round, number: 1, tournament: tournament, season: league.season)
        create(:tournament_round, number: 2, tournament: tournament, season: league.season)
        activator.call
      end

      it 'sets league status to active' do
        expect(league.reload).to be_active
      end

      it 'creates tours' do
        expect(league.tours.count).to eq(2)
      end

      it 'does not create auctions' do
        expect(league.auctions.count).to eq(0)
      end
    end

    context 'when league has teams' do
      before do
        create(:team, league: league, tournament: tournament)
        create(:team, league: league, tournament: tournament)
        create(:tournament_round, number: 1, tournament: tournament, season: league.season)
        activator.call
      end

      it 'sets league status to active' do
        expect(league.reload).to be_active
      end

      it 'creates results for existing teams' do
        expect(league.results.count).to eq(2)
      end

      it 'creates tours' do
        expect(league.tours.count).to eq(1)
      end

      it 'does not create auctions' do
        expect(league.auctions.count).to eq(0)
      end
    end

    context 'when league has tour_difference' do
      let(:league) { create(:league, tournament: tournament, tour_difference: 1) }

      before do
        3.times { |i| create(:tournament_round, number: i + 1, tournament: tournament, season: league.season) }
        activator.call
      end

      it 'creates tours respecting tour_difference' do
        expect(league.tours.count).to eq(2)
      end
    end
  end
end

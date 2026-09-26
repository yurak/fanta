RSpec.describe Results::HistoryRebuilder do
  subject(:rebuild) { described_class.call(league) }

  let(:league) { create(:league) }

  context 'without a league' do
    let(:league) { nil }

    it { expect(rebuild).to be(false) }
  end

  context 'with closed tours stored out of round order' do
    let(:replayed) { [] }

    before do
      create(:closed_tour, league: league, number: 7)
      create(:closed_tour, league: league, number: 2)
      create(:set_lineup_tour, league: league, number: 9)
      allow(Results::Updater).to receive(:call) { |tour| replayed << tour.number }
    end

    it 'replays the closed tours by round number, earliest first' do
      rebuild

      expect(replayed).to eq([2, 7])
    end

    it 'leaves tours that are still open alone' do
      rebuild

      expect(replayed).not_to include(9)
    end
  end

  context 'with a result carrying stale history' do
    let(:team) { create(:team, league: league) }
    let!(:result) { create(:result, league: league, team: team, points: 12, history: '[{"pos":1}]') }

    before { allow(Results::Updater).to receive(:call) }

    it 'clears the history before replaying' do
      rebuild

      expect(result.reload.history).to eq('[]')
    end

    it 'clears the accumulated points' do
      rebuild

      expect(result.reload.points).to eq(0)
    end
  end
end

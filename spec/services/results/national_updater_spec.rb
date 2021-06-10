RSpec.describe Results::NationalUpdater do
  describe '#call' do
    subject(:updater) { described_class.new(tour) }

    let(:tour) { create(:closed_tour) }

    context 'with blank tour' do
      let(:tour) { nil }

      it { expect(updater.call).to eq(false) }
    end

    context 'with not closed tour' do
      let(:tour) { create(:tour) }

      it { expect(updater.call).to eq(false) }
    end

    context 'when tour without lineups' do
      it { expect(updater.call).to eq(false) }
    end

    context 'when tour with lineups' do
      let(:team1) { create(:team, :with_result) }
      let(:team2) { create(:team, :with_result) }

      before do
        create(:lineup, :with_team_and_score_six, team: team1, tour: tour)
        create(:lineup, :with_team_and_score_seven, team: team2, tour: tour)

        updater.call
      end

      it { expect(team1.results.last.total_score).to eq(67) }
      it { expect(team1.results.last.points).to eq(18) }
      it { expect(team1.results.last.wins).to eq(0) }
      it { expect(team1.results.last.draws).to eq(1) }
      it { expect(team2.results.last.total_score).to eq(82) }
      it { expect(team2.results.last.points).to eq(25) }
      it { expect(team2.results.last.wins).to eq(1) }
      it { expect(team2.results.last.draws).to eq(1) }
    end
  end
end

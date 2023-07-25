RSpec.describe Results::NationalUpdater do
  describe '#call' do
    subject(:updater) { described_class.new(tour) }

    let(:tour) { create(:closed_tour) }

    context 'with blank tour' do
      let(:tour) { nil }

      it { expect(updater.call).to be(false) }
    end

    context 'with not closed tour' do
      let(:tour) { create(:tour) }

      it { expect(updater.call).to be(false) }
    end

    context 'when tour without lineups' do
      it { expect(updater.call).to be(false) }
    end

    context 'when tour with lineups' do
      let(:team_one) { create(:team, :with_result) }
      let(:team_two) { create(:team, :with_result) }

      before do
        create(:lineup, :with_team_and_score_six, team: team_one, tour: tour)
        create(:lineup, :with_team_and_score_seven, team: team_two, tour: tour)

        updater.call
      end

      it { expect(team_one.results.last.total_score).to eq(67) }
      it { expect(team_one.results.last.points).to eq(18) }
      it { expect(team_one.results.last.wins).to eq(0) }
      it { expect(team_one.results.last.draws).to eq(1) }
      it { expect(team_two.results.last.total_score).to eq(82) }
      it { expect(team_two.results.last.points).to eq(25) }
      it { expect(team_two.results.last.wins).to eq(1) }
      it { expect(team_two.results.last.draws).to eq(1) }
    end
  end
end

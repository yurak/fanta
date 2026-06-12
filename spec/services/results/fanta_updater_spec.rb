RSpec.describe Results::FantaUpdater do
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
      let(:team_one) { create(:team, :with_result, league: tour.league) }
      let(:team_two) { create(:team, :with_result, league: tour.league) }
      let(:team_forty) { create(:team, :with_result, league: tour.league) }
      let!(:team_forty_one) { create(:team, :with_result, league: tour.league) }

      before do
        create(:lineup, :with_team_and_score_six, team: team_one, tour: tour)
        create(:lineup, :with_team_and_score_seven, team: team_two, tour: tour)
        37.times { create(:lineup, team: create(:team, :with_result, league: tour.league), tour: tour, final_score: 62) }
        create(:lineup, :with_team_and_score_five, team: team_forty, tour: tour)

        updater.call
      end

      it { expect(team_one.results.last.total_score).to eq(66) }
      it { expect(team_one.results.last.points).to eq(54) }
      it { expect(team_one.results.last.best_lineup).to eq(66) }
      it { expect(team_one.results.last.draws).to eq(1) }
      it { expect(team_one.results.last.position).to eq(2) }
      it { expect(team_one.results.last.secondary_position).to eq(2) }
      it { expect(team_one.results.last.history_arr.last['p']).to eq(54) }
      it { expect(team_one.results.last.history_arr.last['pos']).to eq(2) }
      it { expect(team_one.results.last.history_arr.last['sec_pos']).to eq(2) }
      it { expect(team_one.results.last.history_arr.last['ts']).to eq('66.0') }
      it { expect(team_two.results.last.total_score).to eq(78) }
      it { expect(team_two.results.last.points).to eq(60) }
      it { expect(team_two.results.last.best_lineup).to eq(78) }
      it { expect(team_two.results.last.draws).to eq(1) }
      it { expect(team_two.results.last.position).to eq(1) }
      it { expect(team_two.results.last.secondary_position).to eq(1) }
      it { expect(team_forty.results.last.total_score).to eq(55) }
      it { expect(team_forty.results.last.points).to eq(1) }
      it { expect(team_forty.results.last.best_lineup).to eq(55) }
      it { expect(team_forty.results.last.draws).to eq(1) }
      it { expect(team_forty.results.last.position).to eq(40) }
      it { expect(team_forty.results.last.secondary_position).to eq(40) }
      it { expect(team_forty_one.results.last.total_score).to eq(55) }
      it { expect(team_forty_one.results.last.points).to eq(0) }
      it { expect(team_forty_one.results.last.best_lineup).to eq(0) }
      it { expect(team_forty_one.results.last.draws).to eq(1) }
      it { expect(team_forty_one.results.last.position).to eq(41) }
      it { expect(team_forty_one.results.last.secondary_position).to eq(41) }
    end

    context 'when team has no result record' do
      let(:tour) { create(:closed_tour) }
      let(:team_without_result) { create(:team, league: tour.league) }

      before do
        create(:lineup, :with_team_and_score_six, team: team_without_result, tour: tour)
      end

      it 'creates result and updates it' do
        updater.call

        result = team_without_result.results.last
        expect(result.total_score).to eq(66)
      end
    end
  end
end

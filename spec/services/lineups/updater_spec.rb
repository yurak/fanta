RSpec.describe Lineups::Updater do
  describe '#call' do
    subject(:updater) { described_class.new(tour) }

    let(:tour) { create(:closed_tour) }

    context 'with blank tour' do
      let(:tour) { nil }

      it { expect(updater.call).to be(false) }
    end

    context 'when tour without lineups' do
      it { expect(updater.call).to be(false) }
    end

    context 'when tour with lineups without scores' do
      let!(:lineup) { create(:lineup, tour: tour) }

      before do
        updater.call
      end

      it 'does not update lineup final_score' do
        expect(lineup.reload.final_score).to eq(0)
      end
    end

    context 'when tour with lineups with scores' do
      let!(:lineup_one) { create(:lineup, :with_team_and_score_five, tour: tour) }
      let!(:lineup_two) { create(:lineup, :with_team_and_score_eight, tour: tour) }

      before do
        updater.call
      end

      it 'updates first lineup final_score' do
        expect(lineup_one.reload.final_score).to eq(55)
      end

      it 'updates first lineup final_goals' do
        expect(lineup_one.reload.final_goals).to eq(0)
      end

      it 'updates last lineup final_score' do
        expect(lineup_two.reload.final_score).to eq(93)
      end

      it 'updates last lineup final_goals' do
        expect(lineup_two.reload.final_goals).to eq(4)
      end
    end
  end
end

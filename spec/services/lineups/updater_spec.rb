RSpec.describe Lineups::Updater do
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
      let!(:lineup1) { create(:lineup, :with_team_and_score_five, tour: tour) }
      let!(:lineup2) { create(:lineup, :with_team_and_score_eight, tour: tour) }

      before do
        updater.call
      end

      it 'updates first lineup final_score' do
        expect(lineup1.reload.final_score).to eq(55)
      end

      it 'updates last lineup final_score' do
        expect(lineup2.reload.final_score).to eq(93)
      end
    end
  end
end

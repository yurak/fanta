RSpec.describe Results::Creator do
  describe '#call' do
    subject(:creator) { described_class.new(league_id) }

    let(:league) { create(:league, :with_five_teams) }
    let(:league_id) { league.id }

    context 'with blank league_id' do
      let(:league_id) { nil }

      it { expect(creator.call).to be(false) }
    end

    context 'when league without teams' do
      let(:league) { create(:league) }

      it { expect(creator.call).to be(false) }
    end

    context 'when league with teams' do
      before do
        creator.call
      end

      it { expect(league.reload.results.count).to eq(5) }
    end
  end
end

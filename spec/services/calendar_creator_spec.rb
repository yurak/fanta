RSpec.describe CalendarCreator do
  describe '#call' do
    subject(:creator) { described_class.new(league_id, max_tours) }

    let(:league_id) { league.id }
    let(:max_tours) { 38 }

    context 'with invalid league id' do
      let(:league_id) { 'invalid' }

      it { expect(creator.call).to eq(false) }
    end

    context 'when there are fewer league teams than allowed' do
      let(:league) { create(:league) }

      it { expect(creator.call).to eq(false) }
    end

    context 'when league without tournament_rounds' do
      let(:league) { create(:league, :with_ten_teams) }

      it { expect(creator.call).to eq(false) }
    end

    context 'with valid params and even teams count' do
      let(:league) { create(:league, :with_ten_teams, tournament: create(:tournament, :with_38_rounds)) }

      before do
        creator.call
      end

      it { expect(league.reload.tours.count).to eq(38) }
      it { expect(league.reload.tours.first.matches.count).to eq(5) }
    end

    context 'with valid params and odd teams count' do
      let(:league) { create(:league, :with_five_teams, tournament: create(:tournament, :with_38_rounds)) }

      before do
        creator.call
      end

      it { expect(league.reload.tours.count).to eq(38) }
      it { expect(league.reload.tours.first.matches.count).to eq(2) }
    end
  end
end

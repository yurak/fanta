RSpec.describe CalendarCreator do
  describe '#call' do
    subject(:creator) { described_class.new(league_id, max_tours) }

    let(:league_id) { league.id }
    let(:max_tours) { 38 }

    context 'with invalid league id' do
      let(:league_id) { 'invalid' }

      it { expect(creator.call).to be(false) }
    end

    context 'when there are fewer league teams than allowed' do
      let(:league) { create(:league) }

      it { expect(creator.call).to be(false) }
    end

    context 'when league without tournament_rounds' do
      let(:league) { create(:league, :with_ten_teams) }

      it { expect(creator.call).to be(false) }
    end

    context 'when max_tours is less than one full rotation' do
      let(:league) { create(:league, :with_ten_teams, tournament: create(:tournament, :with_38_rounds)) }
      let(:max_tours) { 3 }

      before { creator.call }

      it 'creates only max_tours tours' do
        expect(league.reload.tours.count).to eq(3)
      end

      it 'creates correct number of matches per tour' do
        expect(league.reload.tours.first.matches.count).to eq(5)
      end
    end

    context 'with home/away rotation across rounds' do
      let(:league) { create(:league, tournament: create(:tournament, :with_38_rounds)) }
      let(:max_tours) { 2 }

      before do
        create_list(:team, 2, league: league)
        creator.call
      end

      it 'uses tour 1 host as tour 2 guest' do
        expect(league.tours.find_by(number: 1).matches.first.host_id).to eq(
          league.tours.find_by(number: 2).matches.first.guest_id
        )
      end

      it 'uses tour 1 guest as tour 2 host' do
        expect(league.tours.find_by(number: 1).matches.first.guest_id).to eq(
          league.tours.find_by(number: 2).matches.first.host_id
        )
      end
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

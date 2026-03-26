RSpec.describe CalendarExtender do
  describe '#call' do
    subject(:extender) { described_class.new(league_id, extra_tours) }

    let(:league_id) { league.id }
    let(:extra_tours) { 6 }

    context 'with invalid league id' do
      let(:league_id) { 'invalid' }

      it { expect(extender.call).to be(false) }
    end

    context 'when there are fewer league teams than allowed' do
      let(:league) { create(:league) }

      it { expect(extender.call).to be(false) }
    end

    context 'when league has no tournament_rounds for new tours' do
      let(:league) { create(:league, :with_ten_teams, tournament: create(:tournament, :with_38_rounds)) }

      before { CalendarCreator.call(league.id, 38) }

      it { expect(extender.call).to be(false) }
    end

    context 'with valid params and even teams count' do
      let(:league) { create(:league, :with_ten_teams, tournament: create(:tournament, :with_36_rounds)) }

      before { CalendarCreator.call(league.id, 30) }

      it 'adds extra tours to existing ones' do
        expect { extender.call }.to change { league.reload.tours.count }.from(30).to(36)
      end

      it 'creates matches for the new tours' do
        extender.call
        new_tours = league.reload.tours.where(number: 31..36)
        expect(new_tours.all? { |t| t.matches.count == 5 }).to be(true)
      end

      it 'does not duplicate existing tours' do
        extender.call
        expect(league.reload.tours.pluck(:number).sort).to eq((1..36).to_a)
      end
    end

    context 'with valid params and odd teams count' do
      let(:league) { create(:league, :with_five_teams, tournament: create(:tournament, :with_36_rounds)) }

      before { CalendarCreator.call(league.id, 30) }

      it 'adds extra tours to existing ones' do
        expect { extender.call }.to change { league.reload.tours.count }.from(30).to(36)
      end

      it 'creates matches for the new tours' do
        extender.call
        new_tours = league.reload.tours.where(number: 31..36)
        expect(new_tours.all? { |t| t.matches.count == 2 }).to be(true)
      end
    end
  end
end

RSpec.describe League, type: :model do
  subject(:league) { create(:league) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to belong_to(:season) }
    it { is_expected.to have_many(:teams).dependent(:destroy) }
    it { is_expected.to have_many(:tours).dependent(:destroy) }
    it { is_expected.to have_many(:results).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of :name }

    it { is_expected.to define_enum_for(:status).with_values(%i[initial active archived]) }
  end

  describe '#active_tour' do
    context 'when tours does not exist' do
      it 'returns nil' do
        expect(league.active_tour).to eq(nil)
      end
    end

    context 'when tours exist' do
      it 'returns first set_lineup tour' do
        tours = create_list(:set_lineup_tour, 3, league: league)

        expect(league.active_tour).to eq(tours.first)
      end

      it 'returns first locked tour' do
        tours = create_list(:locked_tour, 2, league: league)

        expect(league.active_tour).to eq(tours.first)
      end
    end
  end

  describe '#active_tour_or_last' do
    context 'when tours does not exist' do
      it 'returns nil' do
        expect(league.active_tour_or_last).to eq(nil)
      end
    end

    context 'when tours exist' do
      it 'returns first set_lineup tour' do
        tours = create_list(:set_lineup_tour, 3, league: league)

        expect(league.active_tour_or_last).to eq(tours.first)
      end

      it 'returns first locked tour' do
        tours = create_list(:locked_tour, 2, league: league)

        expect(league.active_tour_or_last).to eq(tours.first)
      end

      it 'returns last closed tour' do
        tours = create_list(:closed_tour, 5, league: league)

        expect(league.active_tour_or_last).to eq(tours.last)
      end
    end
  end

  describe '#leader' do
    context 'when results does not exist' do
      it 'returns nil' do
        expect(league.leader).to eq(nil)
      end
    end

    context 'when results exist' do
      it 'returns team which result has more points' do
        create(:result, points: 15, league: league)
        result = create(:result, points: 35, league: league)
        create(:result, points: 25, league: league)

        expect(league.leader).to eq(result.team)
      end
    end
  end

  describe '#cleansheet_zone' do
    context 'without cleansheet_m value' do
      let(:league) { create(:league, cleansheet_m: false) }

      it 'returns classic array' do
        expect(league.cleansheet_zone).to eq(%w[Por Dc Ds Dd])
      end
    end

    context 'with cleansheet_m value' do
      it 'returns extended array' do
        expect(league.cleansheet_zone).to eq(%w[Por Dc Ds Dd M])
      end
    end
  end

  describe '.counters' do
    context 'when leagues does not exist' do
      it 'returns all leagues nil' do
        expect(described_class.counters(nil)).to eq('All leagues' => nil)
      end
    end

    context 'when leagues exist' do
      let(:counters) do
        { 'All leagues' => 5,
          'Bundesliga' => 3,
          'Serie A' => 2 }
      end

      it 'returns hash with leagues count' do
        create_list(:league, 2, tournament: Tournament.find(1))
        create_list(:league, 3, tournament: Tournament.find(3))
        leagues = described_class.all

        expect(described_class.counters(leagues)).to eq(counters)
      end
    end
  end
end

RSpec.describe Scores::Injectors::Strategy do
  describe '#call' do
    subject(:strategy) { described_class.call(tour) }

    context 'with serie_a tour' do
      let(:tour) { create(:serie_a_tour) }

      it 'returns calcio injector' do
        expect(strategy).to eq(Scores::Injectors::Calcio)
      end
    end

    context 'with epl tour' do
      let(:tour) { create(:epl_tour) }

      it 'returns fotmob injector' do
        expect(strategy).to eq(Scores::Injectors::Fotmob)
      end
    end

    context 'with bundes tour' do
      let(:tour) { create(:bundes_tour) }

      it 'returns fotmob injector' do
        expect(strategy).to eq(Scores::Injectors::Fotmob)
      end
    end

    context 'with laliga tour' do
      let(:tour) { create(:laliga_tour) }

      it 'returns fotmob injector' do
        expect(strategy).to eq(Scores::Injectors::Fotmob)
      end
    end

    context 'with ligue 1 tour' do
      let(:tour) { create(:ligue1_tour) }

      it 'returns fotmob injector' do
        expect(strategy).to eq(Scores::Injectors::Fotmob)
      end
    end

    context 'with euro tour' do
      let(:tour) { create(:euro_tour) }

      it 'returns fotmob injector' do
        expect(strategy).to eq(Scores::Injectors::Fotmob)
      end
    end

    context 'with test tournament tour' do
      let(:league) { create(:league, tournament: create(:tournament, code: 'test')) }
      let(:tour) { create(:tour, league: league) }

      it 'returns fake injector' do
        expect(strategy).to eq(Scores::Injectors::Fake)
      end
    end
  end
end

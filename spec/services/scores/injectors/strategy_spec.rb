RSpec.describe Scores::Injectors::Strategy do
  describe '#call' do
    subject(:strategy) { described_class.call(tour) }

    context 'with italy tour' do
      let(:tour) { create(:italy_tour) }

      it 'returns calcio injector' do
        expect(strategy).to eq(Scores::Injectors::Calcio)
      end
    end

    context 'with england tour' do
      let(:tour) { create(:england_tour) }

      it 'returns fotmob injector' do
        expect(strategy).to eq(Scores::Injectors::Fotmob)
      end
    end

    context 'with germany tour' do
      let(:tour) { create(:germany_tour) }

      it 'returns fotmob injector' do
        expect(strategy).to eq(Scores::Injectors::Fotmob)
      end
    end

    context 'with spain tour' do
      let(:tour) { create(:spain_tour) }

      it 'returns fotmob injector' do
        expect(strategy).to eq(Scores::Injectors::Fotmob)
      end
    end

    context 'with france tour' do
      let(:tour) { create(:france_tour) }

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

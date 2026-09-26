RSpec.describe LeaguesHelper do
  # The Round link is rendered on tour, match and lineup pages too, and there it must keep the round
  # already on screen instead of sending the manager to the league's default one.
  describe '#league_round_tour(league)' do
    let(:league) { create(:league) }
    let!(:default_tour) { create(:set_lineup_tour, league: league, number: 4) }

    context 'when no tour is on the page' do
      it 'falls back to the league default' do
        expect(helper.league_round_tour(league)).to eq(default_tour)
      end
    end

    context 'when a tour page is open' do
      let(:opened) { create(:closed_tour, league: league, number: 2) }

      before do
        on_page = opened
        helper.define_singleton_method(:tour) { on_page }
      end

      it 'keeps that tour' do
        expect(helper.league_round_tour(league)).to eq(opened)
      end
    end

    context 'when a match page is open' do
      let(:opened) { create(:closed_tour, league: league, number: 3) }

      before do
        on_page = instance_double(Match, tour: opened)
        helper.define_singleton_method(:match) { on_page }
      end

      it 'keeps the tour of that match' do
        expect(helper.league_round_tour(league)).to eq(opened)
      end
    end

    context 'when the open tour belongs to another league' do
      before do
        on_page = create(:closed_tour, league: create(:league), number: 9)
        helper.define_singleton_method(:tour) { on_page }
      end

      it 'falls back to the league default' do
        expect(helper.league_round_tour(league)).to eq(default_tour)
      end
    end
  end

  describe '#league_link(league)' do
    let(:league) { create(:league) }

    context 'without active tour and results' do
      it 'returns league results path' do
        expect(helper.league_link(league)).to eq(league_path(league))
      end
    end

    context 'without active tour and with results' do
      before { create(:result, league: league) }

      it 'returns league results path' do
        expect(helper.league_link(league)).to eq(league_results_path(league))
      end
    end

    context 'with active tour' do
      let!(:tour) { create(:tour, league: league) }

      it 'returns tour path' do
        expect(helper.league_link(league)).to eq(tour_path(tour))
      end
    end
  end
end

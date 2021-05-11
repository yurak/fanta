RSpec.describe Tour, type: :model do
  subject(:tour) { create(:tour) }

  describe 'Associations' do
    it { is_expected.to belong_to(:league) }
    it { is_expected.to belong_to(:tournament_round) }
    it { is_expected.to have_many(:matches).dependent(:destroy) }
    it { is_expected.to have_many(:lineups).dependent(:destroy) }
    it { is_expected.to delegate_method(:teams).to(:league) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:status).with_values(%i[inactive set_lineup locked closed postponed]) }
  end

  describe '#locked_or_postponed?' do
    context 'with inactive status' do
      it 'returns false' do
        expect(tour.locked_or_postponed?).to eq(false)
      end
    end

    context 'with set_lineup status' do
      let(:tour) { create(:set_lineup_tour) }

      it 'returns false' do
        expect(tour.locked_or_postponed?).to eq(false)
      end
    end

    context 'with locked status' do
      let(:tour) { create(:locked_tour) }

      it 'returns false' do
        expect(tour.locked_or_postponed?).to eq(true)
      end
    end

    context 'with postponed status' do
      let(:tour) { create(:postponed_tour) }

      it 'returns false' do
        expect(tour.locked_or_postponed?).to eq(true)
      end
    end

    context 'with closed status' do
      let(:tour) { create(:closed_tour) }

      it 'returns false' do
        expect(tour.locked_or_postponed?).to eq(false)
      end
    end
  end

  describe '#deadlined?' do
    context 'with inactive status' do
      it 'returns false' do
        expect(tour.deadlined?).to eq(false)
      end
    end

    context 'with set_lineup status' do
      let(:tour) { create(:set_lineup_tour) }

      it 'returns false' do
        expect(tour.deadlined?).to eq(false)
      end
    end

    context 'with locked status' do
      let(:tour) { create(:locked_tour) }

      it 'returns false' do
        expect(tour.deadlined?).to eq(true)
      end
    end

    context 'with postponed status' do
      let(:tour) { create(:postponed_tour) }

      it 'returns false' do
        expect(tour.deadlined?).to eq(true)
      end
    end

    context 'with closed status' do
      let(:tour) { create(:closed_tour) }

      it 'returns false' do
        expect(tour.deadlined?).to eq(true)
      end
    end
  end

  describe '#unlocked?' do
    context 'with inactive status' do
      it 'returns false' do
        expect(tour.unlocked?).to eq(true)
      end
    end

    context 'with set_lineup status' do
      let(:tour) { create(:set_lineup_tour) }

      it 'returns false' do
        expect(tour.unlocked?).to eq(true)
      end
    end

    context 'with locked status' do
      let(:tour) { create(:locked_tour) }

      it 'returns false' do
        expect(tour.unlocked?).to eq(false)
      end
    end

    context 'with postponed status' do
      let(:tour) { create(:postponed_tour) }

      it 'returns false' do
        expect(tour.unlocked?).to eq(false)
      end
    end

    context 'with closed status' do
      let(:tour) { create(:closed_tour) }

      it 'returns false' do
        expect(tour.unlocked?).to eq(false)
      end
    end
  end

  describe '#match_players' do
    context 'without match players' do
      it 'returns empty array' do
        expect(tour.match_players).to eq([])
      end
    end

    context 'with match players' do
      it 'returns match players' do
        lineup = create(:lineup, :with_match_players, tour: tour)

        expect(tour.match_players).to eq(lineup.match_players)
      end
    end
  end

  describe '#next_round' do
    context 'without other tours' do
      it 'returns nil' do
        expect(tour.next_round).to eq(nil)
      end
    end

    context 'when other league tours with lower numbers' do
      let(:tour) { create(:tour, number: 3) }

      before do
        create(:tour, league: tour.league, number: 1)
        create(:tour, league: tour.league, number: 2)
      end

      it 'returns nil' do
        expect(tour.next_round).to eq(nil)
      end
    end

    context 'when tours with upper numbers' do
      let(:tour) { create(:tour, number: 1) }
      let!(:next_tour) { create(:tour, league: tour.league, number: 2) }

      before do
        create(:tour, league: tour.league, number: 3)
      end

      it 'returns next round' do
        expect(tour.next_round).to eq(next_tour)
      end
    end
  end

  describe '#prev_round' do
    context 'without other tours' do
      it 'returns nil' do
        expect(tour.prev_round).to eq(nil)
      end
    end

    context 'when other league tours with upper numbers' do
      let(:tour) { create(:tour, number: 1) }

      before do
        create(:tour, league: tour.league, number: 2)
        create(:tour, league: tour.league, number: 3)
      end

      it 'returns nil' do
        expect(tour.prev_round).to eq(nil)
      end
    end

    context 'when tours with lower numbers' do
      let(:tour) { create(:tour, number: 3) }
      let!(:prev_tour) { create(:tour, league: tour.league, number: 2) }

      before do
        create(:tour, league: tour.league, number: 1)
      end

      it 'returns previous round' do
        expect(tour.prev_round).to eq(prev_tour)
      end
    end
  end
end

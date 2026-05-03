RSpec.describe League do
  subject(:league) { create(:league) }

  describe 'Associations' do
    it { is_expected.to belong_to(:division).optional }
    it { is_expected.to belong_to(:season) }
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to have_many(:auctions).dependent(:destroy) }
    it { is_expected.to have_many(:teams).dependent(:destroy) }
    it { is_expected.to have_many(:transfers).dependent(:destroy) }
    it { is_expected.to have_many(:tours).dependent(:destroy) }
    it { is_expected.to have_many(:results).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:season_id) }

    it { is_expected.to define_enum_for(:auction_type).with_values(%i[blind_bids live]) }
    it { is_expected.to define_enum_for(:cloning_status).with_values(%i[unclonable cloneable]) }
    it { is_expected.to define_enum_for(:status).with_values(%i[initial active archived]) }
    it { is_expected.to define_enum_for(:transfer_status).with_values(%i[closed open]) }
  end

  describe '.without_demo_from_old_seasons' do
    let!(:old_season) { create(:season) }
    let!(:current_season) { create(:season) }

    let!(:demo_in_current) { create(:active_league, season: current_season, demo: true) }
    let!(:demo_in_old) { create(:active_league, season: old_season, demo: true) }
    let!(:regular_in_old) { create(:active_league, season: old_season) }

    it 'includes demo leagues from current season' do
      expect(described_class.without_demo_from_old_seasons).to include(demo_in_current)
    end

    it 'excludes demo leagues from old seasons' do
      expect(described_class.without_demo_from_old_seasons).not_to include(demo_in_old)
    end

    it 'includes non-demo leagues from old seasons' do
      expect(described_class.without_demo_from_old_seasons).to include(regular_in_old)
    end
  end

  describe '#division_with_name' do
    context 'when league without division' do
      it 'returns league name' do
        expect(league.division_with_name).to eq(league.name)
      end
    end

    context 'when league with division' do
      let(:division) { create(:division) }

      before do
        league.update(division: division)
      end

      it 'returns league name with division name' do
        expect(league.division_with_name).to eq("#{league.name} (#{division.name})")
      end
    end
  end

  describe '#all_tours_closed?' do
    context 'when league has no tours' do
      it { expect(league.all_tours_closed?).to be(false) }
    end

    context 'when all tours are closed' do
      before { create_list(:closed_tour, 3, league: league) }

      it { expect(league.all_tours_closed?).to be(true) }
    end

    context 'when some tours are not closed' do
      before do
        create(:closed_tour, league: league)
        create(:tour, league: league)
      end

      it { expect(league.all_tours_closed?).to be(false) }
    end
  end

  describe '#active_tour' do
    context 'when tours does not exist' do
      it 'returns nil' do
        expect(league.active_tour).to be_nil
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
        expect(league.active_tour_or_last).to be_nil
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
        expect(league.leader).to be_nil
      end
    end

    context 'when results exist' do
      it 'returns team which result has more points' do
        create(:result, points: 15, league: league)
        result = create(:result, points: 35, league: league)
        create(:result, points: 24, league: league)

        expect(league.leader).to eq(result.team)
      end
    end
  end

  describe '#chart_data' do
    context 'when league does not have closed tour' do
      it 'returns empty hash' do
        expect(league.chart_data).to eq({})
      end
    end

    context 'when league has closed tour' do
      let!(:result_one) do
        create(:result, team: create(:team, league: league), league: league, history: [nil, { pos: 1 }, { pos: 2 }].to_json)
      end
      let!(:result_two) do
        create(:result, team: create(:team, league: league), league: league, history: [nil, { pos: 2 }, { pos: 1 }].to_json)
      end

      before do
        create(:closed_tour, number: 1, league: league)
        create(:closed_tour, number: 2, league: league)
      end

      it 'returns hash with tour labels' do
        expect(JSON.parse(league.chart_data)['labels']).to eq([1, 2])
      end

      it 'returns hash with teams datasets' do
        expect(JSON.parse(league.chart_data)['datasets']).to eq([{ 'backgroundColor' => '#007bff', 'borderColor' => '#007bff',
                                                                   'data' => [1, 2], 'label' => result_one.team.human_name },
                                                                 { 'backgroundColor' => '#fd7e14', 'borderColor' => '#fd7e14',
                                                                   'data' => [2, 1], 'label' => result_two.team.human_name }])
      end
    end
  end
end

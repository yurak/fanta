RSpec.describe Tour, type: :model do
  subject(:tour) { create(:tour) }

  describe 'Associations' do
    it { is_expected.to belong_to(:league) }
    it { is_expected.to belong_to(:tournament_round) }
    it { is_expected.to have_many(:matches).dependent(:destroy) }
    it { is_expected.to have_many(:lineups).dependent(:destroy) }
    it { is_expected.to have_many(:round_players).through(:tournament_round) }
    it { is_expected.to delegate_method(:teams).to(:league) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:status).with_values(%i[inactive set_lineup locked closed postponed]) }
    it { is_expected.to define_enum_for(:bench_status).with_values(%i[default_bench expanded]) }
  end

  describe '#locked_or_postponed?' do
    context 'with inactive status' do
      it { expect(tour.locked_or_postponed?).to be(false) }
    end

    context 'with set_lineup status' do
      let(:tour) { create(:set_lineup_tour) }

      it { expect(tour.locked_or_postponed?).to be(false) }
    end

    context 'with locked status' do
      let(:tour) { create(:locked_tour) }

      it { expect(tour.locked_or_postponed?).to be(true) }
    end

    context 'with postponed status' do
      let(:tour) { create(:postponed_tour) }

      it { expect(tour.locked_or_postponed?).to be(true) }
    end

    context 'with closed status' do
      let(:tour) { create(:closed_tour) }

      it { expect(tour.locked_or_postponed?).to be(false) }
    end
  end

  describe '#deadlined?' do
    context 'with inactive status' do
      it { expect(tour.deadlined?).to be(false) }
    end

    context 'with set_lineup status' do
      let(:tour) { create(:set_lineup_tour) }

      it { expect(tour.deadlined?).to be(false) }
    end

    context 'with locked status' do
      let(:tour) { create(:locked_tour) }

      it { expect(tour.deadlined?).to be(true) }
    end

    context 'with postponed status' do
      let(:tour) { create(:postponed_tour) }

      it { expect(tour.deadlined?).to be(true) }
    end

    context 'with closed status' do
      let(:tour) { create(:closed_tour) }

      it { expect(tour.deadlined?).to be(true) }
    end
  end

  describe '#unlocked?' do
    context 'with inactive status' do
      it { expect(tour.unlocked?).to be(true) }
    end

    context 'with set_lineup status' do
      let(:tour) { create(:set_lineup_tour) }

      it { expect(tour.unlocked?).to be(true) }
    end

    context 'with locked status' do
      let(:tour) { create(:locked_tour) }

      it { expect(tour.unlocked?).to be(false) }
    end

    context 'with postponed status' do
      let(:tour) { create(:postponed_tour) }

      it { expect(tour.unlocked?).to be(false) }
    end

    context 'with closed status' do
      let(:tour) { create(:closed_tour) }

      it { expect(tour.unlocked?).to be(false) }
    end
  end

  describe '#mantra?' do
    context 'without tournament_round matches' do
      it { expect(tour.mantra?).to be(false) }
    end

    context 'with national_match' do
      before do
        create(:national_match, tournament_round: tour.tournament_round)
      end

      it { expect(tour.mantra?).to be(false) }
    end

    context 'with tournament_match' do
      before do
        create(:tournament_match, tournament_round: tour.tournament_round)
      end

      it { expect(tour.mantra?).to be(true) }
    end
  end

  describe '#national?' do
    context 'without tournament_round matches' do
      it { expect(tour.national?).to be(false) }
    end

    context 'with tournament_match' do
      before do
        create(:tournament_match, tournament_round: tour.tournament_round)
      end

      it { expect(tour.national?).to be(false) }
    end

    context 'with national_match' do
      before do
        create(:national_match, tournament_round: tour.tournament_round)
      end

      it { expect(tour.national?).to be(true) }
    end
  end

  describe '#fanta?' do
    context 'with not eurocup tournament and without tournament_round matches' do
      it { expect(tour.fanta?).to be(false) }
    end

    context 'with eurocup tournament' do
      let(:tournament_round) { create(:tournament_round, tournament: Tournament.find_by(eurocup: true)) }
      let(:tour) { create(:tour, tournament_round: tournament_round) }

      it { expect(tour.fanta?).to be(true) }
    end

    context 'with national_match' do
      before do
        create(:national_match, tournament_round: tour.tournament_round)
      end

      it { expect(tour.fanta?).to be(true) }
    end
  end

  describe '#eurocup?' do
    context 'with not eurocup tournament' do
      it { expect(tour.eurocup?).to be(false) }
    end

    context 'with eurocup tournament' do
      let(:tournament_round) { create(:tournament_round, tournament: Tournament.find_by(eurocup: true)) }
      let(:tour) { create(:tour, tournament_round: tournament_round) }

      it { expect(tour.eurocup?).to be(true) }
    end
  end

  describe '#national_teams_count' do
    context 'without national matches' do
      it 'returns 0' do
        expect(tour.national_teams_count).to eq(0)
      end
    end

    context 'with national matches' do
      it 'returns national teams count' do
        create_list(:national_match, 3, tournament_round: tour.tournament_round)

        expect(tour.national_teams_count).to eq(6)
      end
    end
  end

  describe '#max_country_players' do
    context 'without national matches' do
      it 'returns 0' do
        expect(tour.max_country_players).to eq(0)
      end
    end

    context 'with 1 national match' do
      it 'returns max_country_players value 7' do
        create(:national_match, tournament_round: tour.tournament_round)

        expect(tour.max_country_players).to eq(7)
      end
    end

    context 'with 2 national matches' do
      it 'returns max_country_players value 4' do
        create_list(:national_match, 2, tournament_round: tour.tournament_round)

        expect(tour.max_country_players).to eq(4)
      end
    end

    context 'with 3 national matches' do
      it 'returns max_country_players value 3' do
        create_list(:national_match, 3, tournament_round: tour.tournament_round)

        expect(tour.max_country_players).to eq(3)
      end
    end

    context 'with 4 national matches' do
      it 'returns max_country_players value 2' do
        create_list(:national_match, 4, tournament_round: tour.tournament_round)

        expect(tour.max_country_players).to eq(2)
      end
    end

    context 'with 5 national matches' do
      it 'returns 0' do
        create_list(:national_match, 5, tournament_round: tour.tournament_round)

        expect(tour.max_country_players).to eq(1)
      end
    end

    context 'with 10 national matches' do
      it 'returns 0' do
        create_list(:national_match, 10, tournament_round: tour.tournament_round)

        expect(tour.max_country_players).to eq(0)
      end
    end

    context 'with eurocup tournament and 8 tournament matches' do
      let(:tournament_round) { create(:tournament_round, tournament: Tournament.find_by(eurocup: true)) }
      let(:tour) { create(:tour, tournament_round: tournament_round) }

      it 'returns max_country_players value 1' do
        create_list(:tournament_match, 8, tournament_round: tournament_round)

        expect(tour.max_country_players).to eq(1)
      end
    end

    context 'with eurocup tournament and without tournament matches' do
      let(:tournament_round) { create(:tournament_round, tournament: Tournament.find_by(eurocup: true)) }
      let(:tour) { create(:tour, tournament_round: tournament_round) }

      it 'returns max_country_players value 0' do
        expect(tour.max_country_players).to eq(0)
      end
    end
  end

  describe '#lineup_exist?(teams)' do
    let!(:team) { create(:team) }

    context 'without team lineup' do
      it { expect(tour.lineup_exist?(team)).to be(false) }
    end

    context 'with team lineup' do
      before do
        create(:lineup, tour: tour, team: team)
      end

      it { expect(tour.lineup_exist?(team)).to be(true) }
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
        expect(tour.next_round).to be_nil
      end
    end

    context 'when other league tours with lower numbers' do
      let(:tour) { create(:tour, number: 3) }

      before do
        create(:tour, league: tour.league, number: 1)
        create(:tour, league: tour.league, number: 2)
      end

      it 'returns nil' do
        expect(tour.next_round).to be_nil
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
        expect(tour.prev_round).to be_nil
      end
    end

    context 'when other league tours with upper numbers' do
      let(:tour) { create(:tour, number: 1) }

      before do
        create(:tour, league: tour.league, number: 2)
        create(:tour, league: tour.league, number: 3)
      end

      it 'returns nil' do
        expect(tour.prev_round).to be_nil
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

  describe '#ordered_lineups' do
    context 'without lineups' do
      it 'returns empty array' do
        expect(tour.ordered_lineups).to eq([])
      end
    end

    context 'with lineups' do
      it 'returns lineups ordered by total score' do
        lineup1 = create(:lineup, :with_team_and_score_six, tour: tour)
        lineup2 = create(:lineup, :with_team_and_score_seven, tour: tour)
        lineup3 = create(:lineup, :with_team_and_score_five, tour: tour)

        expect(tour.ordered_lineups).to eq([lineup2, lineup1, lineup3])
      end
    end
  end
end

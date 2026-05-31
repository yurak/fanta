RSpec.describe Tour do
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
      it 'returns max_country_players value 8' do
        create(:national_match, tournament_round: tour.tournament_round)

        expect(tour.max_country_players).to eq(8)
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

        expect(tour.max_country_players).to eq(2)
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

  describe '#min_country_players' do
    context 'without national matches' do
      it 'returns 0' do
        expect(tour.min_country_players).to eq(0)
      end
    end

    context 'with 1 national match' do
      it 'returns min_country_players value 7' do
        create(:national_match, tournament_round: tour.tournament_round)

        expect(tour.min_country_players).to eq(8)
      end
    end

    context 'with 2 national matches' do
      it 'returns min_country_players value 4' do
        create_list(:national_match, 2, tournament_round: tour.tournament_round)

        expect(tour.min_country_players).to eq(4)
      end
    end

    context 'with 3 national matches' do
      it 'returns min_country_players value 3' do
        create_list(:national_match, 3, tournament_round: tour.tournament_round)

        expect(tour.min_country_players).to eq(2)
      end
    end

    context 'with 4 national matches' do
      it 'returns min_country_players value 2' do
        create_list(:national_match, 4, tournament_round: tour.tournament_round)

        expect(tour.min_country_players).to eq(2)
      end
    end

    context 'with 5 national matches' do
      it 'returns 0' do
        create_list(:national_match, 5, tournament_round: tour.tournament_round)

        expect(tour.min_country_players).to eq(1)
      end
    end

    context 'with 10 national matches' do
      it 'returns 0' do
        create_list(:national_match, 10, tournament_round: tour.tournament_round)

        expect(tour.min_country_players).to eq(0)
      end
    end

    context 'with eurocup tournament and 8 tournament matches' do
      let(:tournament_round) { create(:tournament_round, tournament: Tournament.find_by(eurocup: true)) }
      let(:tour) { create(:tour, tournament_round: tournament_round) }

      it 'returns min_country_players value 1' do
        create_list(:tournament_match, 8, tournament_round: tournament_round)

        expect(tour.min_country_players).to eq(1)
      end
    end

    context 'with eurocup tournament and without tournament matches' do
      let(:tournament_round) { create(:tournament_round, tournament: Tournament.find_by(eurocup: true)) }
      let(:tour) { create(:tour, tournament_round: tournament_round) }

      it 'returns min_country_players value 0' do
        expect(tour.min_country_players).to eq(0)
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

        expect(tour.match_players).to match_array(lineup.match_players)
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
        lineup_one = create(:lineup, :with_team_and_score_six, tour: tour)
        lineup_two = create(:lineup, :with_team_and_score_seven, tour: tour)
        lineup_three = create(:lineup, :with_team_and_score_five, tour: tour)

        expect(tour.ordered_lineups).to eq([lineup_two, lineup_one, lineup_three])
      end
    end

    context 'with lineups with equal total score' do
      let(:league) { create(:league, :fanta_league) }
      let(:fanta_tour) do
        create(:closed_tour, league: league, tournament_round: create(:tournament_round, tournament: league.tournament))
      end

      it 'orders by best main score as tiebreaker' do
        lineup_one = create(:lineup, :with_fanta_score_five, tour: fanta_tour, final_score: 55)
        lineup_two = create(:lineup, :with_fanta_score_five, tour: fanta_tour, final_score: 55)
        lineup_two.match_players.main.last.round_player.update(score: 9.0)

        expect(fanta_tour.ordered_lineups).to eq([lineup_two, lineup_one])
      end

      it 'orders by best bench score when main scores are equal' do
        lineup_one = create(:lineup, :with_fanta_score_five, tour: fanta_tour, final_score: 55)
        lineup_two = create(:lineup, :with_fanta_score_five, tour: fanta_tour, final_score: 55)
        lineup_two.match_players.subs_bench.last.round_player.update(score: 9.0)

        expect(fanta_tour.ordered_lineups).to eq([lineup_two, lineup_one])
      end

      context 'when bench total score differs' do
        let(:lineup_one) { create(:lineup, :with_fanta_score_five, tour: fanta_tour, final_score: 55) }
        let(:lineup_two) { create(:lineup, :with_fanta_score_five, tour: fanta_tour, final_score: 55) }

        before do
          lineup_one.match_players.subs_bench.first.round_player.update(score: 9.0)
          lineup_two.match_players.subs_bench.first.round_player.update(score: 9.0)
          lineup_two.match_players.subs_bench.second.round_player.update(score: 9.0)
        end

        it 'orders by bench total score' do
          expect(fanta_tour.ordered_lineups).to eq([lineup_two, lineup_one])
        end
      end

      it 'orders by created_at when all scores are equal' do
        lineup_one = create(:lineup, :with_fanta_score_five, tour: fanta_tour, final_score: 55, created_at: 1.hour.ago)
        lineup_two = create(:lineup, :with_fanta_score_five, tour: fanta_tour, final_score: 55, created_at: 2.hours.ago)

        expect(fanta_tour.ordered_lineups).to eq([lineup_two, lineup_one])
      end
    end
  end

  describe '#autobot' do
    context 'when not fanta' do
      before { allow(Substitutes::AutoBot).to receive(:call) }

      it 'does not call AutoBot' do
        tour.autobot(preview: true)
        expect(Substitutes::AutoBot).not_to have_received(:call)
      end

      context 'with matches' do
        before do
          create(:match, tour: tour)
          create(:match, tour: tour)
        end

        it 'calls autobot on each match' do
          call_count = 0
          allow_any_instance_of(Match).to receive(:autobot) { call_count += 1 }
          tour.autobot(preview: true)
          expect(call_count).to eq(2)
        end
      end
    end

    context 'when fanta?' do
      let(:league) { create(:league, :fanta_league) }
      let(:tour) { create(:closed_tour, league: league, tournament_round: create(:tournament_round, tournament: league.tournament)) }

      before do
        allow(Substitutes::AutoBot).to receive(:call)
        create(:lineup, tour: tour)
        create(:lineup, tour: tour)
      end

      it 'does not call AutoBot when no subs missed' do
        tour.autobot(preview: true)
        expect(Substitutes::AutoBot).not_to have_received(:call)
      end

      context 'when lineup has missed subs' do
        before do
          allow_any_instance_of(Lineup).to receive(:subs_missed?).and_return(true)
          allow(Substitutes::AutoBot).to receive(:call)
        end

        it 'calls AutoBot for each lineup' do
          tour.autobot(preview: true)
          expect(Substitutes::AutoBot).to have_received(:call).twice
        end
      end
    end
  end

  describe '#subs_preview' do
    context 'without lineups' do
      it 'returns empty array' do
        expect(tour.subs_preview).to eq([])
      end
    end

    context 'with lineups without substitutes' do
      before do
        create(:lineup, tour: tour)
        create(:lineup, tour: tour)
      end

      it 'returns array of empty arrays' do
        expect(tour.subs_preview).to eq([[], []])
      end
    end

    context 'with lineup that has substitutes' do
      let(:substitutes_data) { [{ 'out' => 'Player A', 'in' => 'Player B' }] }

      before { create(:lineup, tour: tour, substitutes: substitutes_data.to_json) }

      it 'returns parsed substitutes' do
        expect(tour.subs_preview).to eq([substitutes_data])
      end
    end
  end

  describe '#subs_missed?' do
    context 'without match_players' do
      it 'returns false' do
        expect(tour.subs_missed?).to be(false)
      end
    end

    context 'with main match_players without score but no subs option' do
      before do
        lineup = create(:lineup, tour: tour)
        create(:match_player, :with_real_position, lineup: lineup)
        allow_any_instance_of(MatchPlayer).to receive(:subs_option_exist?).and_return(false)
      end

      it 'returns false' do
        expect(tour.subs_missed?).to be(false)
      end
    end

    context 'with main match_player without score that has a subs option' do
      before do
        lineup = create(:lineup, tour: tour)
        create(:match_player, :with_real_position, lineup: lineup)
        allow_any_instance_of(MatchPlayer).to receive(:subs_option_exist?).and_return(true)
      end

      it 'returns true' do
        expect(tour.subs_missed?).to be(true)
      end
    end
  end
end

RSpec.describe Team, type: :model do
  subject(:team) { create(:team) }

  describe 'Associations' do
    it { is_expected.to belong_to(:league) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:auction_bids).dependent(:destroy) }
    it { is_expected.to have_many(:player_teams).dependent(:destroy) }
    it { is_expected.to have_many(:players).through(:player_teams) }
    it { is_expected.to have_many(:lineups).order('tour_id desc').dependent(:destroy).inverse_of(:team) }
    it { is_expected.to have_many(:results).dependent(:destroy) }
    it { is_expected.to have_many(:transfers).dependent(:destroy) }

    it {
      expect(team).to have_many(:host_matches).class_name('Match').with_foreign_key('host_id')
                                              .dependent(:destroy).inverse_of(:host)
    }

    it {
      expect(team).to have_many(:guest_matches).class_name('Match').with_foreign_key('guest_id')
                                               .dependent(:destroy).inverse_of(:guest)
    }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of :name }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(18) }
    it { is_expected.to validate_presence_of :code }
    it { is_expected.to validate_uniqueness_of(:code).case_insensitive }
    it { is_expected.to validate_length_of(:code).is_at_least(2).is_at_most(4) }
    it { is_expected.to validate_length_of(:human_name).is_at_least(2).is_at_most(18) }
  end

  describe '#league_matches' do
    context 'without matches' do
      it 'returns empty array' do
        expect(team.league_matches).to eq([])
      end
    end

    context 'without league matches' do
      let(:team) { create(:team, :with_matches) }

      it 'returns empty array' do
        expect(team.league_matches).to eq([])
      end
    end

    context 'with league matches' do
      let(:matches) { create_list(:match, 3, host: team, tour: create(:tour, league: team.league)) }

      it 'returns array with matches' do
        expect(team.league_matches).to eq(matches)
      end
    end
  end

  describe '#logo_path' do
    context 'when logo does not exist' do
      it 'returns default path' do
        expect(team.logo_path).to eq('default_logo.png')
      end
    end

    context 'when logo url exists' do
      let(:team) { create(:team, logo_url: logo_url) }
      let(:logo_url) { 'url/logo.png' }

      it 'returns path to team logo' do
        expect(team.logo_path).to eq(logo_url)
      end
    end
  end

  describe '#next_round' do
    context 'when league without tours' do
      it 'returns nil' do
        expect(team.next_round).to eq(nil)
      end
    end

    context 'when league with initial tours' do
      it 'returns first initial tour' do
        tours = create_list(:tour, 3, league: team.league)

        expect(team.next_round).to eq(tours.first)
      end
    end

    context 'when league with initial tours and one set_lineup' do
      it 'returns first active tour' do
        create_list(:tour, 3, league: team.league)
        tour = create(:tour, league: team.league, status: :set_lineup)

        expect(team.next_round).to eq(tour)
      end
    end
  end

  describe '#opponent_by_match(match)' do
    context 'when team is host' do
      it 'returns guest team' do
        match = create(:match, host: team, tour: create(:tour, league: team.league))

        expect(team.opponent_by_match(match)).to eq(match.guest)
      end
    end

    context 'when team is guest' do
      it 'returns host team' do
        match = create(:match, guest: team, tour: create(:tour, league: team.league))

        expect(team.opponent_by_match(match)).to eq(match.host)
      end
    end
  end

  describe '#next_opponent' do
    context 'when league without tours and matches' do
      it 'returns nil' do
        expect(team.next_opponent).to eq(nil)
      end
    end

    context 'when league with tours and without matches' do
      it 'returns nil' do
        create_list(:tour, 3, league: team.league)

        expect(team.next_opponent).to eq(nil)
      end
    end

    context 'when league with tours and matches and team is host' do
      it 'returns first match guest' do
        matches = create_list(:match, 3, host: team, tour: create(:tour, league: team.league))

        expect(team.next_opponent).to eq(matches.first.guest)
      end
    end

    context 'when league with tours and matches and team is guest' do
      it 'returns first match host' do
        matches = create_list(:match, 3, guest: team, tour: create(:tour, league: team.league))

        expect(team.next_opponent).to eq(matches.first.host)
      end
    end
  end

  describe '#players_not_in(lineup)' do
    context 'without lineup' do
      it 'returns nil' do
        expect(team.players_not_in(nil)).to eq(nil)
      end
    end

    context 'with lineup' do
      let(:team) { create(:team, :with_lineup) }
      let(:lineup) { team.lineups.last }

      it 'returns players' do
        expect(team.players_not_in(lineup).count).to eq(7)
      end
    end
  end

  describe '#best_lineup' do
    context 'without lineup' do
      it 'returns nil' do
        expect(team.best_lineup).to eq(nil)
      end
    end

    context 'with lineup' do
      it 'returns lineup with best total score' do
        create(:lineup, :with_team_and_score_six, team: team, tour: create(:closed_tour, league: team.league))
        lineup2 = create(:lineup, :with_team_and_score_seven, team: team, tour: create(:closed_tour, league: team.league))
        create(:lineup, :with_team_and_score_five, team: team, tour: create(:closed_tour, league: team.league))

        expect(team.best_lineup).to eq(lineup2)
      end
    end
  end

  describe '#vacancies' do
    context 'without players' do
      it 'returns max value' do
        expect(team.vacancies).to eq(Team::MAX_PLAYERS)
      end
    end

    context 'with players' do
      let(:team) { create(:team, :with_15_players) }

      it 'returns number of empty vacancies' do
        expect(team.vacancies).to eq(10)
      end
    end

    context 'with max number of players' do
      let(:team) { create(:team, :with_players) }

      it 'returns zero' do
        expect(team.vacancies).to eq(0)
      end
    end
  end

  describe '#max_rate' do
    context 'with full budget' do
      it 'returns max_rate value' do
        expect(team.max_rate).to eq(236)
      end
    end

    context 'with few players' do
      let(:team) { create(:team, :with_15_players, budget: 99) }

      it 'returns max_rate value' do
        expect(team.max_rate).to eq(90)
      end
    end

    context 'with max number of players and positive budget' do
      let(:team) { create(:team, :with_players, budget: 13) }

      it 'returns zero' do
        expect(team.max_rate).to eq(0)
      end
    end
  end

  describe '#sales_period?' do
    context 'without auctions' do
      it 'returns false' do
        expect(team.sales_period?).to eq(false)
      end
    end

    context 'without sales auctions' do
      before do
        create(:auction, league: team.league)
      end

      it 'returns false' do
        expect(team.sales_period?).to eq(false)
      end
    end

    context 'with sales auctions' do
      before do
        create(:auction, status: 'sales', league: team.league)
      end

      it 'returns true' do
        expect(team.sales_period?).to eq(true)
      end
    end
  end
end

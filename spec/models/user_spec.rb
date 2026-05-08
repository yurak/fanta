RSpec.describe User do
  subject(:user) { create(:user) }

  describe 'Associations' do
    it { is_expected.to have_many(:join_requests).dependent(:destroy) }
    it { is_expected.to have_many(:joins).dependent(:destroy) }
    it { is_expected.to have_many(:teams).dependent(:destroy) }
    it { is_expected.to have_many(:leagues).through(:teams) }
    it { is_expected.to have_many(:results).through(:teams) }
    it { is_expected.to have_many(:lineups).through(:teams) }
    it { is_expected.to have_many(:transfers).through(:teams) }
    it { is_expected.to have_many(:player_requests).dependent(:destroy) }
    it { is_expected.to have_many(:user_titles).dependent(:destroy) }
    it { is_expected.to have_one(:user_profile).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :email }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.not_to allow_value('test').for(:email) }
    it { is_expected.not_to allow_value('test@test').for(:email) }
    it { is_expected.to allow_value('test@test.com').for(:email) }
    it { is_expected.to validate_length_of(:email).is_at_least(6).is_at_most(50) }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(20) }
    it { is_expected.to validate_presence_of :role }

    it { is_expected.to define_enum_for(:role).with_values(%i[customer admin moderator]) }
    it { is_expected.to define_enum_for(:status).with_values(%i[initial named with_avatar with_team configured]) }
    it { is_expected.to define_enum_for(:locale).with_values(%i[en ua]) }
  end

  describe 'Callbacks' do
    it 'generates unsubscribe token on create' do
      expect(user.unsubscribe_token).to be_present
    end

    it 'does not override existing unsubscribe token' do
      user = create(:user, unsubscribe_token: 'existing-token')

      expect(user.unsubscribe_token).to eq('existing-token')
    end
  end

  describe '.champions' do
    let!(:second_champion) { create(:user, champion_number: 2) }
    let!(:first_champion) { create(:user, champion_number: 1) }

    before do
      create(:user, champion_number: nil)
    end

    it 'returns champions ordered by champion number' do
      expect(described_class.champions).to eq([first_champion, second_champion])
    end
  end

  describe '#local_time(time, format)' do
    let(:time) { Time.utc(2025, 1, 2, 12, 30) }

    context 'without time' do
      it 'returns nil' do
        expect(user.local_time(nil)).to be_nil
      end
    end

    context 'with user time zone' do
      let(:user) { build(:user, time_zone: 'UTC') }

      it 'returns formatted time in user time zone' do
        expect(user.local_time(time, '%H:%M')).to eq('12:30')
      end
    end

    context 'without user time zone' do
      let(:user) { build(:user, time_zone: nil) }

      it 'returns formatted time in default time zone' do
        expect(user.local_time(time, '%H:%M')).to eq('14:30')
      end
    end
  end

  describe '#can_moderate?' do
    context 'with customer role' do
      it 'returns false' do
        expect(user.can_moderate?).to be(false)
      end
    end

    context 'with admin role' do
      let(:user) { create(:admin) }

      it 'returns false' do
        expect(user.can_moderate?).to be(true)
      end
    end

    context 'with moderator role' do
      let(:user) { create(:moderator) }

      it 'returns false' do
        expect(user.can_moderate?).to be(true)
      end
    end
  end

  describe '#team_by_league(league)' do
    let(:league) { create(:league) }

    context 'without league' do
      it { expect(user.team_by_league(nil)).to be_nil }
    end

    context 'without team in league' do
      it { expect(user.team_by_league(league)).to be_nil }
    end

    context 'with team in league' do
      let!(:team) { create(:team, user: user, league: league) }

      it { expect(user.team_by_league(league)).to eq(team) }
    end
  end

  describe '#lineup_by_tour(tour)' do
    let(:tour) { create(:tour) }

    context 'without team in league' do
      it { expect(user.lineup_by_tour(tour)).to be_nil }
    end

    context 'without lineup for tour' do
      before do
        create(:team, user: user, league: tour.league)
      end

      it { expect(user.lineup_by_tour(tour)).to be_nil }
    end

    context 'with lineup for tour' do
      let!(:team) { create(:team, user: user, league: tour.league) }
      let!(:lineup) { create(:lineup, tour: tour, team: team) }

      it { expect(user.lineup_by_tour(tour)).to eq(lineup) }
    end
  end

  describe '#avatar_path' do
    context 'with avatar url' do
      let(:user) { create(:user, avatar_url: 'https://example.com/avatar.png') }

      it 'returns avatar url' do
        expect(user.avatar_path).to eq('https://example.com/avatar.png')
      end
    end

    context 'with default avatar' do
      it { expect(user.avatar_path).to eq('avatars/avatar_1.png') }
    end

    context 'with custom avatar' do
      let(:user) { create(:user, avatar: '3') }

      it 'returns avatar path' do
        expect(user.avatar_path).to eq('avatars/avatar_3.png')
      end
    end
  end

  describe '#initial_avatar?' do
    context 'with default avatar' do
      it { expect(user.initial_avatar?).to be(true) }
    end

    context 'with custom avatar' do
      let(:user) { create(:user, avatar: '3') }

      it 'returns avatar path' do
        expect(user.initial_avatar?).to be(false)
      end
    end
  end

  describe '#titles' do
    context 'without titles' do
      it 'returns empty array' do
        expect(user.titles).to eq([])
      end
    end

    context 'with titles' do
      let(:result) { create(:result, title: true) }

      it 'returns results with titles' do
        expect(user.titles).to eq([])
      end
    end

    context 'with finished title result' do
      let(:league) { create(:archived_league) }
      let(:team) { create(:team, user: user, league: league) }
      let!(:result) { create(:result, team: team, league: league, title: true) }

      it 'returns title results' do
        expect(user.titles).to eq([result])
      end
    end
  end

  describe '#win_rate' do
    context 'without results' do
      it 'returns zero' do
        expect(user.win_rate).to eq(0)
      end
    end

    context 'without mantra results' do
      let(:league) { create(:league, :fanta_league) }
      let(:team) { create(:team, user: user, league: league) }

      before do
        create(:result, team: team, league: league)
      end

      it 'returns zero' do
        expect(user.win_rate).to eq(0)
      end
    end

    context 'with mantra results' do
      let(:team) { create(:team, user: user) }

      context 'without played matches' do
        before do
          create(:result, team: team, league: team.league)
        end

        it 'returns zero' do
          expect(user.win_rate).to eq(0)
        end
      end

      context 'with played matches' do
        before do
          create(:result, team: team, league: team.league, wins: 5, draws: 2, loses: 1)
        end

        it 'returns win rate' do
          expect(user.win_rate).to eq(62.5)
        end
      end
    end
  end

  describe '#average_mantra_ts' do
    context 'without lineups' do
      it 'returns zero' do
        expect(user.average_mantra_ts).to eq(0)
      end
    end

    context 'with lineups' do
      let(:team) { create(:team, user: user) }

      before do
        create(:lineup, team: team, final_score: 100, tour: create(:closed_tour))
        create(:lineup, team: team, final_score: 70, tour: create(:closed_tour))
      end

      it 'returns average total score' do
        expect(user.average_mantra_ts).to eq(85)
      end
    end
  end

  describe '#average_fanta_ts' do
    context 'without lineups' do
      it 'returns zero' do
        expect(user.average_fanta_ts).to eq(0)
      end
    end

    context 'with lineups' do
      let(:team) { create(:team, user: user) }

      before do
        tournament = create(:fanta_tournament)
        create(:lineup, team: team, final_score: 115,
                        tour: create(:closed_tour, tournament_round: create(:tournament_round, tournament: tournament)))
        create(:lineup, team: team, final_score: 85,
                        tour: create(:closed_tour, tournament_round: create(:tournament_round, tournament: tournament)))
      end

      it 'returns average total score' do
        expect(user.average_fanta_ts).to eq(100)
      end
    end
  end

  describe '#mantra_best_ts' do
    context 'without lineups' do
      it 'returns zero' do
        expect(user.mantra_best_ts).to eq(0)
      end
    end

    context 'with lineups' do
      let(:team) { create(:team, user: user) }

      before do
        create(:lineup, team: team, final_score: 100, tour: create(:closed_tour))
        create(:lineup, team: team, final_score: 70, tour: create(:closed_tour))
      end

      it 'returns average total score' do
        expect(user.mantra_best_ts).to eq(100)
      end
    end
  end

  describe '#fanta_best_ts' do
    context 'without lineups' do
      it 'returns zero' do
        expect(user.fanta_best_ts).to eq(0)
      end
    end

    context 'with lineups' do
      let(:team) { create(:team, user: user) }

      before do
        tournament = create(:fanta_tournament)
        create(:lineup, team: team, final_score: 115,
                        tour: create(:closed_tour, tournament_round: create(:tournament_round, tournament: tournament)))
        create(:lineup, team: team, final_score: 85,
                        tour: create(:closed_tour, tournament_round: create(:tournament_round, tournament: tournament)))
      end

      it 'returns average total score' do
        expect(user.fanta_best_ts).to eq(115)
      end
    end
  end

  describe '#average_position' do
    context 'without results' do
      it 'returns zero' do
        expect(user.average_position).to eq(0)
      end
    end

    context 'without finished results' do
      let(:team) { create(:team, user: user) }

      before do
        create(:result, team: team, league: team.league)
      end

      it 'returns zero' do
        expect(user.average_position).to eq(0)
      end
    end

    context 'without finished mantra results' do
      let(:league) { create(:league, :fanta_league) }
      let(:team) { create(:team, user: user, league: league) }

      before do
        create(:result, team: team, league: league, position: 3)
      end

      it 'returns zero' do
        expect(user.average_position).to eq(0)
      end
    end

    context 'with finished mantra results without position' do
      let(:league) { create(:archived_league) }
      let(:team) { create(:team, user: user, league: league) }

      before do
        create(:result, team: team, league: league)
      end

      it 'returns zero' do
        expect(user.average_position).to eq(0)
      end
    end

    context 'with finished mantra results with position' do
      let(:team) { create(:team, user: user, league: create(:archived_league)) }
      let(:team_two) { create(:team, user: user, league: create(:archived_league)) }

      before do
        create(:result, team: team, league: team.league, position: 3)
        create(:result, team: team_two, league: team_two.league, position: 2)
      end

      it 'returns win rate' do
        expect(user.average_position).to eq(2.5)
      end
    end
  end

  describe '#promotions' do
    let(:league) { create(:archived_league, promotion: 1) }
    let(:team) { create(:team, user: user, league: league) }
    let!(:promoted_result) { create(:result, team: team, league: league, position: 1) }

    before do
      create(:result, league: league, position: 2)
    end

    it 'returns promoted finished results' do
      expect(user.promotions).to eq([promoted_result])
    end
  end

  describe '#relegations' do
    let(:league) { create(:archived_league, relegation: 1) }
    let(:team) { create(:team, user: user, league: league) }
    let!(:relegated_result) { create(:result, team: team, league: league, position: 2) }

    before do
      create(:result, league: league, position: 1)
    end

    it 'returns relegated finished results' do
      expect(user.relegations).to eq([relegated_result])
    end
  end

  describe '#fanta_top' do
    let(:league) { create(:league, :fanta_league) }
    let(:team) { create(:team, user: user, league: league) }
    let!(:top_result) { create(:result, team: team, league: league, position: 10) }

    before do
      create(:result, league: league, position: 11)
    end

    it 'returns top ten fanta results' do
      expect(user.fanta_top).to eq([top_result])
    end
  end

  describe '#fanta_top_ts' do
    let(:league) { create(:league, :fanta_league) }
    let(:team) { create(:team, user: user, league: league) }
    let!(:top_result) { create(:result, team: team, league: league, secondary_position: 10) }

    before do
      create(:result, league: league, secondary_position: 11)
    end

    it 'returns top ten fanta total score results' do
      expect(user.fanta_top_ts).to eq([top_result])
    end
  end
end

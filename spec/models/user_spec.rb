RSpec.describe User do
  subject(:user) { create(:user) }

  describe 'Associations' do
    it { is_expected.to have_many(:join_requests).dependent(:destroy) }
    it { is_expected.to have_many(:teams).dependent(:destroy) }
    it { is_expected.to have_many(:leagues).through(:teams) }
    it { is_expected.to have_many(:player_requests).dependent(:destroy) }
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

  describe '#average_total_score' do
    context 'without lineups' do
      it 'returns zero' do
        expect(user.average_total_score).to eq(0)
      end
    end

    context 'with lineups' do
      let(:team) { create(:team, user: user) }

      before do
        create(:lineup, team: team, final_score: 100)
        create(:lineup, team: team, final_score: 70)
      end

      it 'returns average total score' do
        expect(user.average_total_score).to eq(85)
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
end

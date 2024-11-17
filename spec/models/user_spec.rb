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
end

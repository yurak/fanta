RSpec.describe User, type: :model do
  subject(:user) { create(:user) }

  describe 'Associations' do
    it { is_expected.to have_many(:teams).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of :email }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.not_to allow_value('test').for(:email) }
    it { is_expected.not_to allow_value('test@test').for(:email) }
    it { is_expected.to allow_value('test@test.com').for(:email) }
    it { is_expected.to validate_length_of(:email).is_at_least(6).is_at_most(50) }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(15).allow_blank }
    it { is_expected.to validate_presence_of :role }

    it { is_expected.to define_enum_for(:role).with_values(%i[customer admin moderator]) }
  end

  describe '#can_moderate?' do
    context 'with customer role' do
      it 'returns false' do
        expect(user.can_moderate?).to eq(false)
      end
    end

    context 'with admin role' do
      let(:user) { create(:admin) }

      it 'returns false' do
        expect(user.can_moderate?).to eq(true)
      end
    end

    context 'with moderator role' do
      let(:user) { create(:moderator) }

      it 'returns false' do
        expect(user.can_moderate?).to eq(true)
      end
    end
  end

  describe '#active_team' do
    context 'without team' do
      it 'returns nil' do
        expect(user.active_team).to eq(nil)
      end
    end

    context 'with one team' do
      it 'returns team' do
        team = create(:team, user: user)

        expect(user.active_team).to eq(team)
      end
    end

    context 'with multiple teams and without active_team_id' do
      it 'returns first team' do
        create_list(:team, 3, user: user)

        expect(user.active_team).to eq(user.teams.first)
      end
    end

    context 'with multiple teams and active_team_id' do
      it 'returns active team' do
        teams = create_list(:team, 3, user: user)
        user.active_team_id = teams.last.id

        expect(user.active_team).to eq(teams.last)
      end
    end
  end

  describe '#active_league' do
    context 'without team' do
      it 'returns nil' do
        expect(user.active_league).to eq(nil)
      end
    end

    context 'with one team' do
      it 'returns team league' do
        team = create(:team, user: user)

        expect(user.active_league).to eq(team.league)
      end
    end

    context 'with multiple teams and without active_team_id' do
      it 'returns first team league' do
        create_list(:team, 3, user: user)

        expect(user.active_league).to eq(user.teams.first.league)
      end
    end

    context 'with multiple teams and active_team_id' do
      it 'returns active team league' do
        create_list(:team, 3, user: user)
        team = create(:team, user: user)
        user.active_team_id = team.id

        expect(user.active_league).to eq(team.league)
      end
    end
  end

  describe '#next_tour' do
    context 'without team' do
      it 'returns nil' do
        expect(user.next_tour).to eq(nil)
      end
    end

    context 'with team and league without rounds' do
      it 'returns nil' do
        create(:team, user: user)

        expect(user.next_tour).to eq(nil)
      end
    end

    context 'with team and league with inactive tours' do
      it 'returns nil' do
        team = create(:team, user: user)
        rounds = create_list(:tour, 5, league: team.league)

        expect(user.next_tour).to eq(rounds.first)
      end
    end
  end

  describe '#avatar_path' do
    context 'with default avatar' do
      it 'returns avatar path' do
        expect(user.avatar_path).to eq('avatars/avatar_1.png')
      end
    end

    context 'with custom avatar' do
      let(:user) { create(:user, avatar: '3') }

      it 'returns avatar path' do
        expect(user.avatar_path).to eq('avatars/avatar_3.png')
      end
    end
  end
end
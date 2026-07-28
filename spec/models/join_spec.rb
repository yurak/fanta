RSpec.describe Join do
  describe 'validations' do
    context 'when user applies to the same tournament twice (non-rejected)' do
      let(:user) { create(:user) }
      let(:tournament) { create(:tournament) }
      let(:first_team) { create(:team) }
      let(:second_team) { create(:team) }

      before { create(:join, user: user, tournament: tournament, team: first_team, status: :pending) }

      it 'is invalid' do
        duplicate = build(:join, user: user, tournament: tournament, team: second_team, status: :pending)
        expect(duplicate).not_to be_valid
      end
    end

    context 'when user applies to the same tournament after a rejection' do
      let(:user) { create(:user) }
      let(:tournament) { create(:tournament) }
      let(:first_team) { create(:team) }
      let(:second_team) { create(:team) }

      before { create(:join, user: user, tournament: tournament, team: first_team, status: :rejected) }

      it 'is valid' do
        new_join = build(:join, user: user, tournament: tournament, team: second_team, status: :pending)
        expect(new_join).to be_valid
      end
    end

    context 'when user applies to a different tournament' do
      let(:user) { create(:user) }
      let(:first_team) { create(:team) }
      let(:second_team) { create(:team) }

      before { create(:join, user: user, tournament: create(:tournament), team: first_team) }

      it 'is valid' do
        new_join = build(:join, user: user, tournament: create(:tournament), team: second_team)
        expect(new_join).to be_valid
      end
    end

    context 'when user re-applies to the same tournament in a new season' do
      let(:user) { create(:user) }
      let(:tournament) { create(:tournament) }
      let(:past_season) { create(:season, start_year: 2023, end_year: 2024) }
      let(:new_season) { create(:season, start_year: 2024, end_year: 2025) }

      before do
        create(:join, :approved, user: user, tournament: tournament, team: create(:team), season: past_season)
      end

      it 'is valid' do
        new_join = build(:join, :pending, user: user, tournament: tournament, team: create(:team), season: new_season)
        expect(new_join).to be_valid
      end
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(initial: 0, pending: 1, approved: 2, rejected: 3) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:tournament) }
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:auction_bid) }
  end

  describe 'default season' do
    it 'assigns the latest season on creation when none is given' do
      create(:season, start_year: 2023, end_year: 2024)
      latest = create(:season, start_year: 2024, end_year: 2025)
      join = create(:join, season: nil)

      expect(join.season).to eq(latest)
    end
  end
end

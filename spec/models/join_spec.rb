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
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(initial: 0, pending: 1, approved: 2, rejected: 3) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:auction_bid) }
  end
end

RSpec.describe WeeklyTeamPlayer do
  describe 'associations' do
    it { is_expected.to belong_to(:weekly_team) }
    it { is_expected.to belong_to(:slot) }
    it { is_expected.to belong_to(:round_player).optional }
    it { is_expected.to belong_to(:player).optional }
  end

  describe 'validations' do
    subject { create(:weekly_team_player) }

    it { is_expected.to validate_uniqueness_of(:slot_id).scoped_to(:weekly_team_id) }

    it 'is valid with a player and no round_player (auction source)' do
      wtp = build(:weekly_team_player, round_player: nil, player: create(:player, :with_pos_por))

      expect(wtp).to be_valid
    end

    it 'is invalid with neither a player nor a round_player' do
      wtp = build(:weekly_team_player, round_player: nil, player: nil)

      expect(wtp).not_to be_valid
    end
  end

  describe '#resolved_player' do
    it 'returns the direct player when present' do
      player = create(:player, :with_pos_por)
      wtp = build(:weekly_team_player, round_player: nil, player: player)

      expect(wtp.resolved_player).to eq(player)
    end

    it 'falls back to the round_player player' do
      wtp = create(:weekly_team_player)

      expect(wtp.resolved_player).to eq(wtp.round_player.player)
    end
  end
end

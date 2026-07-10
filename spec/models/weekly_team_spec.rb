RSpec.describe WeeklyTeam do
  subject(:weekly_team) { build(:weekly_team) }

  describe 'associations' do
    it { is_expected.to belong_to(:team_module) }
    it { is_expected.to belong_to(:season) }
    it { is_expected.to belong_to(:tournament).optional }
    it { is_expected.to have_many(:weekly_team_players).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_numericality_of(:number).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:mode) }

    context 'when source is season' do
      subject { build(:weekly_team, source: :season, tournament: nil) }

      it { is_expected.not_to be_valid }
    end

    context 'when source is avg' do
      subject { build(:weekly_team, source: :avg, tournament: nil) }

      it { is_expected.not_to be_valid }
    end

    context 'when source is avg with mode flop' do
      subject { build(:weekly_team, source: :avg, mode: :flop, tournament: Tournament.first) }

      it { is_expected.not_to be_valid }
    end

    context 'when source is avg with mode top' do
      subject { build(:weekly_team, source: :avg, mode: :top, tournament: Tournament.first) }

      it { is_expected.to be_valid }
    end

    context 'when source is round' do
      subject { build(:weekly_team, source: :round, tournament: nil) }

      it { is_expected.to be_valid }
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:mode).with_values(top: 'top', flop: 'flop').backed_by_column_of_type(:string) }

    it 'defines source enum with prefix' do
      expect(weekly_team).to define_enum_for(:source).with_values(round: 'round', season: 'season',
                                                                  avg: 'avg').backed_by_column_of_type(:string).with_prefix(:source)
    end
  end

  describe '#round_ids' do
    it 'serializes round ids as array' do
      weekly_team = create(:weekly_team, round_ids: [1, 2, 3])

      expect(weekly_team.reload.round_ids).to eq([1, 2, 3])
    end
  end

  describe '.defence_bonus_for' do
    it 'returns 0 with no defenders' do
      expect(described_class.defence_bonus_for([])).to eq(0)
    end

    it 'returns 0 when the average is below the minimum' do
      expect(described_class.defence_bonus_for([6.0, 6.0])).to eq(0)
    end

    it 'returns the minimal bonus at the minimum threshold' do
      expect(described_class.defence_bonus_for([7.0, 7.0])).to eq(1)
    end

    it 'scales the bonus with the average' do
      expect(described_class.defence_bonus_for([7.5, 7.5])).to eq(3)
    end

    it 'caps the bonus at the maximum threshold' do
      expect(described_class.defence_bonus_for([8.0, 9.0])).to eq(5)
    end
  end

  describe '#defence_bonus' do
    it 'averages only the central defenders and ignores other positions' do
      weekly_team = create(:weekly_team, source: :round)
      add_player(weekly_team, position: 'Dc', score: 7.0)
      add_player(weekly_team, position: 'Dc', score: 7.0)
      add_player(weekly_team, position: 'C', score: 2.0) # midfielder — excluded

      expect(weekly_team.defence_bonus).to eq(1)
    end

    it 'returns 0 for avg source teams' do
      weekly_team = create(:weekly_team, source: :avg, mode: :top, tournament: Tournament.first || create(:tournament))
      add_player(weekly_team, position: 'Dc', score: 8.0)

      expect(weekly_team.defence_bonus).to eq(0)
    end
  end

  describe '#total_score' do
    it 'adds the defence bonus to the sum of player totals' do
      weekly_team = create(:weekly_team, source: :round)
      add_player(weekly_team, position: 'Dc', score: 7.0, total: 7.0)
      add_player(weekly_team, position: 'Dc', score: 7.0, total: 7.0)

      expect(weekly_team.total_score).to eq(15.0) # 7 + 7 + bonus 1
    end
  end

  def add_player(weekly_team, position:, score:, total: score)
    slot = create(:slot, team_module: weekly_team.team_module, position: position)
    round_player = create(:round_player, score: score)
    create(:weekly_team_player, weekly_team: weekly_team, slot: slot, round_player: round_player, total: total)
  end
end

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
end

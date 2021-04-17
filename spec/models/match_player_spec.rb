RSpec.describe MatchPlayer, type: :model do
  subject(:match_player) { create(:match_player) }

  let(:match_player_with_score) { create(:match_player, :with_score) }

  describe 'Associations' do
    it { is_expected.to belong_to(:lineup) }
    it { is_expected.to belong_to(:round_player) }
    it { is_expected.to delegate_method(:league).to(:lineup) }
    it { is_expected.to delegate_method(:team).to(:lineup) }
    it { is_expected.to delegate_method(:tour).to(:lineup) }
    it { is_expected.to delegate_method(:player).to(:round_player) }
    it { is_expected.to delegate_method(:score).to(:round_player) }
    it { is_expected.to delegate_method(:result_score).to(:round_player) }
    it { is_expected.to delegate_method(:goals).to(:round_player) }
    it { is_expected.to delegate_method(:assists).to(:round_player) }
    it { is_expected.to delegate_method(:missed_goals).to(:round_player) }
    it { is_expected.to delegate_method(:caught_penalty).to(:round_player) }
    it { is_expected.to delegate_method(:missed_penalty).to(:round_player) }
    it { is_expected.to delegate_method(:scored_penalty).to(:round_player) }
    it { is_expected.to delegate_method(:failed_penalty).to(:round_player) }
    it { is_expected.to delegate_method(:own_goals).to(:round_player) }
    it { is_expected.to delegate_method(:yellow_card).to(:round_player) }
    it { is_expected.to delegate_method(:red_card).to(:round_player) }
    it { is_expected.to delegate_method(:club_played_match?).to(:round_player) }
    it { is_expected.to delegate_method(:position_names).to(:player) }
    it { is_expected.to delegate_method(:name).to(:player) }
    it { is_expected.to delegate_method(:first_name).to(:player) }
    it { is_expected.to delegate_method(:club).to(:player) }
    it { is_expected.to delegate_method(:teams).to(:player) }
  end

  describe 'Validations' do
    it { is_expected.to define_enum_for(:subs_status).with_values(%i[initial get_out get_in not_in_squad]) }
  end

  describe '#not_played?' do
    context 'without score and when club did not play' do
      it 'returns false' do
        expect(match_player.not_played?).to eq(false)
      end
    end

    context 'without score and when club already played' do
      it 'returns true' do
        allow(match_player.round_player).to receive(:club_played_match?).and_return(true)

        expect(match_player.not_played?).to eq(true)
      end
    end

    context 'with score and when club did not play' do
      it 'returns false' do
        expect(match_player_with_score.not_played?).to eq(false)
      end
    end

    context 'with score and when club already played' do
      it 'returns false' do
        allow(match_player_with_score.round_player).to receive(:club_played_match?).and_return(true)

        expect(match_player_with_score.not_played?).to eq(false)
      end
    end
  end

  describe '#position_malus?' do
    context 'without real position' do
      it 'returns false' do
        expect(match_player.position_malus?).to eq(false)
      end
    end

    context 'with real position that is among player positions' do
      let(:match_player) { create(:match_player, :with_real_position) }

      it 'returns false' do
        expect(match_player.position_malus?).to eq(false)
      end
    end

    context 'with real position that is not among player positions' do
      let(:match_player) { create(:match_player, :with_position_malus) }

      it 'returns true' do
        expect(match_player.position_malus?).to eq(true)
      end
    end
  end

  describe '#total_score' do
    context 'without score' do
      it 'returns zero' do
        expect(match_player.total_score).to eq(0)
      end
    end

    context 'with score' do
      it 'returns total score value' do
        expect(match_player_with_score.total_score).to eq(6)
      end
    end

    context 'with score and position malus' do
      let(:match_player) { create(:match_player, :with_score, position_malus: 3) }

      it 'returns total score value with malus' do
        expect(match_player.total_score).to eq(3)
      end
    end

    context 'with score and cleansheet and without real_position' do
      let(:match_player) { create(:match_player, :with_score, cleansheet: true) }

      it 'returns total score value without cs bonus' do
        expect(match_player.total_score).to eq(6)
      end
    end

    context 'with score and cleansheet' do
      let(:match_player) { create(:dc_match_player, cleansheet: true) }

      it 'returns total score value with cs bonus' do
        expect(match_player.total_score).to eq(7)
      end
    end

    context 'with score and cleansheet on def position but with E player position' do
      let(:match_player) { create(:e_match_player, real_position: 'Dd', cleansheet: true) }

      it 'returns total score value without cs bonus' do
        expect(match_player.total_score).to eq(6)
      end
    end

    context 'with score and cleansheet on M position with cleansheet_m league bonus' do
      let(:match_player) { create(:m_match_player, cleansheet: true) }

      it 'returns total score value with M cs bonus' do
        expect(match_player.total_score).to eq(6.5)
      end
    end

    context 'with score and cleansheet on M position without cleansheet_m bonus' do
      let(:match_player) { create(:m_match_player, real_position: 'M/C', cleansheet: true) }

      it 'returns total score value without cs bonus' do
        allow(match_player.league).to receive(:cleansheet_m).and_return(false)

        expect(match_player.total_score).to eq(6)
      end
    end

    context 'with score and cleansheet on M position but with C player position' do
      let(:match_player) { create(:c_match_player, real_position: 'M/C', cleansheet: true) }

      it 'returns total score value without cs bonus' do
        expect(match_player.total_score).to eq(6)
      end
    end

    context 'with score and failed_penalty without league custom_bonuses' do
      it 'returns recounted total score value' do
        allow(match_player_with_score.league).to receive(:custom_bonuses).and_return(true)
        allow(match_player_with_score.round_player).to receive(:failed_penalty).and_return(1)

        expect(match_player_with_score.total_score).to eq(3)
      end
    end

    context 'with score, league custom_bonuses and failed_penalty' do
      it 'returns recounted total score value' do
        allow(match_player_with_score.league).to receive(:custom_bonuses).and_return(true)
        allow(match_player_with_score.league).to receive(:failed_penalty).and_return(2)
        allow(match_player_with_score.round_player).to receive(:failed_penalty).and_return(1)

        expect(match_player_with_score.total_score).to eq(4)
      end
    end

    context 'with score and missed_goals without league custom_bonuses' do
      it 'returns total score value' do
        allow(match_player_with_score.round_player).to receive(:missed_goals).and_return(1)

        expect(match_player_with_score.total_score).to eq(5)
      end
    end

    context 'with score and missed_goals with league custom_bonuses for not Por position' do
      let(:match_player) { create(:dc_match_player) }

      it 'returns total score value' do
        allow(match_player.league).to receive(:custom_bonuses).and_return(true)
        allow(match_player.round_player).to receive(:missed_goals).and_return(1)

        expect(match_player.total_score).to eq(5)
      end
    end

    context 'with score and missed_goals with league custom_bonuses for main Por position' do
      let(:match_player) { create(:por_match_player) }

      it 'returns recounted total score value' do
        allow(match_player.league).to receive(:custom_bonuses).and_return(true)
        allow(match_player.round_player).to receive(:missed_goals).and_return(2)

        expect(match_player.total_score).to eq(2)
      end
    end

    context 'with score and missed_goals with league custom_bonuses for reserve Por position' do
      let(:match_player) { create(:por_match_player, real_position: nil) }

      it 'returns recounted total score value' do
        allow(match_player.league).to receive(:custom_bonuses).and_return(true)
        allow(match_player.round_player).to receive(:missed_goals).and_return(1)

        expect(match_player.total_score).to eq(4)
      end
    end

    context 'with score and goals without league custom_bonuses and recount_goals' do
      it 'returns total score value' do
        allow(match_player_with_score.round_player).to receive(:goals).and_return(1)

        expect(match_player_with_score.total_score).to eq(9)
      end
    end

    context 'with score and goals with league custom_bonuses and recount_goals for not forward positions' do
      let(:match_player) { create(:dc_match_player) }

      it 'returns total score value' do
        allow(match_player.league).to receive(:custom_bonuses).and_return(true)
        allow(match_player.league).to receive(:recount_goals).and_return(true)
        allow(match_player.round_player).to receive(:goals).and_return(1)

        expect(match_player.total_score).to eq(9)
      end
    end

    context 'with score and goals with league custom_bonuses and recount_goals for W/A, T/A positions' do
      let(:match_player) { create(:w_match_player) }

      it 'returns recounted total score value' do
        allow(match_player.league).to receive(:custom_bonuses).and_return(true)
        allow(match_player.league).to receive(:recount_goals).and_return(true)
        allow(match_player.round_player).to receive(:goals).and_return(1)

        expect(match_player.total_score).to eq(8.5)
      end
    end

    context 'with score and goals with league custom_bonuses and recount_goals for A/Pc positions' do
      let(:match_player) { create(:pc_match_player) }

      it 'returns recounted total score value' do
        allow(match_player.league).to receive(:custom_bonuses).and_return(true)
        allow(match_player.league).to receive(:recount_goals).and_return(true)
        allow(match_player.round_player).to receive(:goals).and_return(1)

        expect(match_player.total_score).to eq(8)
      end
    end
  end

  describe '#available_positions' do
    context 'without real position' do
      it 'returns empty array' do
        expect(match_player.available_positions).to eq([])
      end
    end

    context 'with real position' do
      let(:match_player) { create(:dc_match_player) }

      it 'returns array with available positions' do
        expect(match_player.available_positions).to eq(%w[Dc Dd Ds])
      end
    end
  end

  describe '#real_position_arr' do
    context 'without real position' do
      it 'returns empty array' do
        expect(match_player.real_position_arr).to eq([])
      end
    end

    context 'with real position' do
      let(:match_player) { create(:w_match_player) }

      it 'returns array with module positions' do
        expect(match_player.real_position_arr).to eq(%w[W A])
      end
    end
  end
end

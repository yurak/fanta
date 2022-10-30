RSpec.describe MatchPlayer do
  subject(:match_player) { create(:match_player) }

  let(:match_player_with_score) { create(:match_player, :with_score) }

  describe 'Associations' do
    it { is_expected.to belong_to(:lineup) }
    it { is_expected.to belong_to(:round_player) }

    it {
      expect(match_player).to have_many(:main_subs).class_name('Substitute').with_foreign_key('main_mp_id')
                                                   .dependent(:destroy).inverse_of(:main_mp)
    }

    it {
      expect(match_player).to have_many(:reserve_subs).class_name('Substitute').with_foreign_key('reserve_mp_id')
                                                      .dependent(:destroy).inverse_of(:reserve_mp)
    }

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
        expect(match_player.not_played?).to be(false)
      end
    end

    context 'without score and when club already played' do
      it 'returns true' do
        allow(match_player.round_player).to receive(:club_played_match?).and_return(true)

        expect(match_player.not_played?).to be(true)
      end
    end

    context 'with score and when club did not play' do
      it 'returns false' do
        expect(match_player_with_score.not_played?).to be(false)
      end
    end

    context 'with score and when club already played' do
      it 'returns false' do
        allow(match_player_with_score.round_player).to receive(:club_played_match?).and_return(true)

        expect(match_player_with_score.not_played?).to be(false)
      end
    end

    context 'when player moved to another tournament' do
      it 'returns true' do
        allow(match_player.round_player).to receive(:another_tournament?).and_return(true)

        expect(match_player.not_played?).to be(true)
      end
    end
  end

  describe '#position_malus?' do
    context 'without real position' do
      it 'returns false' do
        expect(match_player.position_malus?).to be(false)
      end
    end

    context 'with real position that is among player positions' do
      let(:match_player) { create(:match_player, :with_real_position) }

      it 'returns false' do
        expect(match_player.position_malus?).to be(false)
      end
    end

    context 'with real position that is not among player positions' do
      let(:match_player) { create(:match_player, :with_position_malus) }

      it 'returns true' do
        expect(match_player.position_malus?).to be(true)
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
      let(:match_player) { create(:match_player, :with_score_and_cleansheet) }

      it 'returns total score value without cs bonus' do
        expect(match_player.total_score).to eq(6)
      end
    end

    context 'with score and cleansheet' do
      let(:match_player) { create(:dc_match_player, round_player: create(:round_player, :with_pos_dc, :with_score_six, cleansheet: true)) }

      it 'returns total score value with cs bonus' do
        expect(match_player.total_score).to eq(7)
      end
    end

    context 'with score and cleansheet on def position but with E player position' do
      let(:match_player) do
        create(:match_player, real_position: 'Dd', round_player: create(:round_player, :with_pos_e, :with_score_six, cleansheet: true))
      end

      it 'returns total score value with E cs bonus' do
        expect(match_player.total_score).to eq(6.5)
      end
    end

    context 'with score and cleansheet on E position with E player position' do
      let(:match_player) do
        create(:match_player, real_position: 'E', round_player: create(:round_player, :with_pos_e, :with_score_six, cleansheet: true))
      end

      it 'returns total score value with E cs bonus' do
        expect(match_player.total_score).to eq(6.5)
      end
    end

    context 'with score and cleansheet on E position with Dd player position' do
      let(:match_player) do
        create(:match_player, real_position: 'E', round_player: create(:round_player, :with_pos_dd, :with_score_six, cleansheet: true))
      end

      it 'returns total score value with E cs bonus' do
        expect(match_player.total_score).to eq(6.5)
      end
    end

    context 'with score and cleansheet on Dc position with Dc and E player positions' do
      let(:match_player) do
        create(:match_player, real_position: 'Dc',
                              round_player: create(:round_player, :with_pos_dc_ds_e, :with_score_six, cleansheet: true))
      end

      it 'returns total score value with Dc cs bonus' do
        expect(match_player.total_score).to eq(7)
      end
    end

    context 'with score and cleansheet on E position with Dc and E player positions' do
      let(:match_player) do
        create(:match_player, real_position: 'E', round_player: create(:round_player, :with_pos_dc_ds_e, :with_score_six, cleansheet: true))
      end

      it 'returns total score value with E cs bonus' do
        expect(match_player.total_score).to eq(6.5)
      end
    end

    context 'with score and cleansheet on W position but with E player position' do
      let(:match_player) do
        create(:match_player, real_position: 'W', round_player: create(:round_player, :with_pos_e, :with_score_six, cleansheet: true))
      end

      it 'returns total score value without cs bonus' do
        expect(match_player.total_score).to eq(6)
      end
    end

    context 'with score and cleansheet on W/A position but with Ds and E player positions' do
      let(:match_player) do
        create(:match_player, real_position: 'W/A',
                              round_player: create(:round_player, :with_pos_dc_ds_e, :with_score_six, cleansheet: true))
      end

      it 'returns total score value without cs bonus' do
        expect(match_player.total_score).to eq(6)
      end
    end

    context 'with score and cleansheet on M position' do
      let(:match_player) { create(:m_match_player, round_player: create(:round_player, :with_pos_m, :with_score_six, cleansheet: true)) }

      it 'returns total score value with M cs bonus' do
        expect(match_player.total_score).to eq(6.5)
      end
    end

    context 'with score and cleansheet on M position but with C player position' do
      let(:match_player) do
        create(:match_player, real_position: 'M/C', round_player: create(:round_player, :with_pos_c, :with_score_six, cleansheet: true))
      end

      it 'returns total score value without cs bonus' do
        expect(match_player.total_score).to eq(6)
      end
    end

    context 'with score and cleansheet on M position but with E and C player position' do
      let(:match_player) do
        create(:match_player, real_position: 'M/C', round_player: create(:round_player, :with_pos_e_c, :with_score_six, cleansheet: true))
      end

      it 'returns total score value without cs bonus' do
        expect(match_player.total_score).to eq(6)
      end
    end

    context 'with score and cleansheet on C position but with M player position' do
      let(:match_player) do
        create(:match_player, real_position: 'C', round_player: create(:round_player, :with_pos_m, :with_score_six, cleansheet: true))
      end

      it 'returns total score value without cs bonus' do
        expect(match_player.total_score).to eq(6)
      end
    end

    context 'with score and cleansheet on Dc position but with M player position' do
      let(:match_player) do
        create(:match_player, real_position: 'Dc', round_player: create(:round_player, :with_pos_m, :with_score_six, cleansheet: true))
      end

      it 'returns total score value with M cs bonus' do
        expect(match_player.total_score).to eq(6.5)
      end
    end

    context 'with score and cleansheet on M position but with Dc player position' do
      let(:match_player) do
        create(:match_player, real_position: 'M', round_player: create(:round_player, :with_pos_dc, :with_score_six, cleansheet: true))
      end

      it 'returns total score value with M cs bonus' do
        expect(match_player.total_score).to eq(6.5)
      end
    end

    context 'with score and failed_penalty' do
      it 'returns recounted total score value' do
        allow(match_player_with_score.round_player).to receive(:failed_penalty).and_return(1)

        expect(match_player_with_score.total_score).to eq(3)
      end
    end

    context 'with score and missed_goals' do
      it 'returns total score value' do
        allow(match_player_with_score.round_player).to receive(:missed_goals).and_return(1)

        expect(match_player_with_score.total_score).to eq(4.5)
      end
    end

    context 'with score and missed_goals for main Por position' do
      let(:match_player) { create(:por_match_player) }

      it 'returns recounted total score value' do
        allow(match_player.round_player).to receive(:missed_goals).and_return(2)

        expect(match_player.total_score).to eq(3)
      end
    end

    context 'with score and goals' do
      it 'returns total score value' do
        allow(match_player_with_score.round_player).to receive(:goals).and_return(1)

        expect(match_player_with_score.total_score).to eq(9)
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
        expect(match_player.available_positions).to eq(%w[Dc Dd Ds M])
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

  describe '#hide_cleansheet?' do
    context 'when match_player at E position with E player position' do
      let(:match_player) { create(:match_player, real_position: 'E', round_player: create(:round_player, :with_pos_e)) }

      it 'returns false' do
        expect(match_player.hide_cleansheet?).to be(false)
      end
    end

    context 'when match_player at W position with E player position' do
      let(:match_player) { create(:match_player, real_position: 'W', round_player: create(:round_player, :with_pos_e)) }

      it 'returns true' do
        expect(match_player.hide_cleansheet?).to be(true)
      end
    end

    context 'when match_player at M position with M player position' do
      let(:match_player) { create(:match_player, real_position: 'M', round_player: create(:round_player, :with_pos_m)) }

      it 'returns false' do
        expect(match_player.hide_cleansheet?).to be(false)
      end
    end

    context 'when match_player at C position with M player position' do
      let(:match_player) { create(:match_player, real_position: 'C', round_player: create(:round_player, :with_pos_m)) }

      it 'returns true' do
        expect(match_player.hide_cleansheet?).to be(true)
      end
    end
  end
end

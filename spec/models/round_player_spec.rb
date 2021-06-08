RSpec.describe RoundPlayer, type: :model do
  subject(:round_player) { create(:round_player) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament_round) }
    it { is_expected.to belong_to(:player) }
    it { is_expected.to have_many(:match_players).dependent(:destroy) }
    it { is_expected.to have_many(:lineups).through(:match_players) }
    it { is_expected.to delegate_method(:position_names).to(:player).allow_nil }
    it { is_expected.to delegate_method(:positions).to(:player).allow_nil }
    it { is_expected.to delegate_method(:name).to(:player).allow_nil }
    it { is_expected.to delegate_method(:first_name).to(:player).allow_nil }
    it { is_expected.to delegate_method(:full_name).to(:player).allow_nil }
    it { is_expected.to delegate_method(:full_name_reverse).to(:player).allow_nil }
    it { is_expected.to delegate_method(:club).to(:player).allow_nil }
    it { is_expected.to delegate_method(:teams).to(:player).allow_nil }
    it { is_expected.to delegate_method(:pseudo_name).to(:player).allow_nil }
  end

  describe '#result_score' do
    context 'with initial_score' do
      it 'returns zero' do
        expect(round_player.result_score).to eq(0)
      end
    end

    context 'without score and with goals' do
      let(:round_player) { create :round_player, goals: 3 }

      it 'returns zero' do
        expect(round_player.result_score).to eq(0)
      end
    end

    context 'with score and goals' do
      let(:round_player) { create :round_player, :with_score_six, goals: 3 }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(15)
      end
    end

    context 'with score and goals and A position' do
      let(:round_player) { create :round_player, :with_pos_a, :with_score_six, goals: 2 }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(11)
      end
    end

    context 'with score and goals and Pc position' do
      let(:round_player) { create :round_player, :with_pos_pc, :with_score_six, goals: 4 }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(14)
      end
    end

    context 'with score and caught penalty' do
      let(:round_player) { create :round_player, :with_score_six, caught_penalty: 1 }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(9)
      end
    end

    context 'with score and scored penalty' do
      let(:round_player) { create :round_player, :with_score_six, scored_penalty: 1 }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(8)
      end
    end

    context 'with score and assist' do
      let(:round_player) { create :round_player, :with_score_six, assists: 1 }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(7)
      end
    end

    context 'with score, goal, scored penalty and assist' do
      let(:round_player) { create :round_player, :with_score_six, goals: 1, scored_penalty: 1, assists: 2 }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(13)
      end
    end

    context 'with score and missed goals' do
      let(:round_player) { create :round_player, :with_score_six, missed_goals: 2 }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(3)
      end
    end

    context 'with score and missed penalty' do
      let(:round_player) { create :round_player, :with_score_six, missed_penalty: 1 }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(5)
      end
    end

    context 'with score and failed penalty' do
      let(:round_player) { create :round_player, :with_score_six, failed_penalty: 1 }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(3)
      end
    end

    context 'with score and own goals' do
      let(:round_player) { create :round_player, :with_score_six, own_goals: 1 }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(4)
      end
    end

    context 'with score and cards' do
      let(:round_player) { create :round_player, :with_score_six, yellow_card: true, red_card: true }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(3.5)
      end
    end

    context 'with score and cards for Por player' do
      let(:round_player) { create :round_player, :with_score_six, :with_pos_por, yellow_card: true, red_card: true }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(2.5)
      end
    end

    context 'with score, bonuses and maluses' do
      let(:round_player) { create :round_player, :with_score_six, yellow_card: true, failed_penalty: 1, goals: 2, assists: 1 }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(9.5)
      end
    end

    context 'with score, cleansheet and Por position' do
      let(:round_player) { create :round_player, :with_score_six, :with_pos_por, cleansheet: true }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(7.5)
      end
    end

    context 'with score, cleansheet and Dc position' do
      let(:round_player) { create :round_player, :with_score_six, :with_pos_dc, cleansheet: true }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(7)
      end
    end

    context 'with score, cleansheet and E position' do
      let(:round_player) { create :round_player, :with_score_six, :with_pos_e, cleansheet: true }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(6.5)
      end
    end

    context 'with score, cleansheet and M position' do
      let(:round_player) { create :round_player, :with_score_six, :with_pos_m, cleansheet: true }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(6.5)
      end
    end

    context 'with score, cleansheet and С position' do
      let(:round_player) { create :round_player, :with_score_six, :with_pos_c, cleansheet: true }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(6)
      end
    end
  end

  describe '#club_played_match?' do
    context 'without tournament match result' do
      it 'returns false' do
        expect(round_player.club_played_match?).to eq(false)
      end
    end

    context 'with not played tournament match' do
      let(:round_player) { create :round_player, :with_tournament_match }

      it 'returns false' do
        expect(round_player.club_played_match?).to eq(false)
      end
    end

    context 'with finished tournament match' do
      let(:round_player) { create :round_player, :with_finished_t_match }

      it 'returns true' do
        expect(round_player.club_played_match?).to eq(true)
      end
    end
  end
end

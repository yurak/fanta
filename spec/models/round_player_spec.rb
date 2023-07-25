RSpec.describe RoundPlayer do
  subject(:round_player) { create(:round_player) }

  describe 'Associations' do
    it { is_expected.to belong_to(:tournament_round) }
    it { is_expected.to belong_to(:player) }
    it { is_expected.to have_many(:match_players).dependent(:destroy) }
    it { is_expected.to have_many(:lineups).through(:match_players) }

    it {
      expect(round_player).to have_many(:in_subs).class_name('Substitute').with_foreign_key('in_rp_id')
                                                 .dependent(:destroy).inverse_of(:in_rp)
    }

    it {
      expect(round_player).to have_many(:out_subs).class_name('Substitute').with_foreign_key('out_rp_id')
                                                  .dependent(:destroy).inverse_of(:out_rp)
    }

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
      let(:round_player) { create(:round_player, goals: 3) }

      it 'returns zero' do
        expect(round_player.result_score).to eq(0)
      end
    end

    context 'with score and goals' do
      let(:round_player) { create(:round_player, :with_score_six, goals: 3) }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(15)
      end
    end

    context 'with score and goals and A position' do
      let(:round_player) { create(:round_player, :with_pos_a, :with_score_six, goals: 2) }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(11)
      end
    end

    context 'with score and goals and Pc position' do
      let(:round_player) { create(:round_player, :with_pos_pc, :with_score_six, goals: 4) }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(14)
      end
    end

    context 'with score and caught penalty' do
      let(:round_player) { create(:round_player, :with_score_six, caught_penalty: 1) }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(9)
      end
    end

    context 'with score and scored penalty' do
      let(:round_player) { create(:round_player, :with_score_six, scored_penalty: 1) }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(8)
      end
    end

    context 'with score and assist' do
      let(:round_player) { create(:round_player, :with_score_six, assists: 1) }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(7)
      end
    end

    context 'with score, goal, scored penalty and assist' do
      let(:round_player) { create(:round_player, :with_score_six, goals: 1, scored_penalty: 1, assists: 2) }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(13)
      end
    end

    context 'with score and missed goals' do
      let(:round_player) { create(:round_player, :with_score_six, missed_goals: 2) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(4)
      end
    end

    context 'with score, missed goals and few saves' do
      let(:round_player) { create(:round_player, :with_score_six, player: create(:player, :with_pos_por), missed_goals: 2, saves: 4) }

      it 'returns score with malus and bonus' do
        expect(round_player.result_score).to eq(4.5)
      end
    end

    context 'with score, missed goals and many saves' do
      let(:round_player) { create(:round_player, :with_score_six, player: create(:player, :with_pos_por), missed_goals: 1, saves: 6) }

      it 'returns score with malus and bonus' do
        expect(round_player.result_score).to eq(6)
      end
    end

    context 'with score and missed penalty' do
      let(:round_player) { create(:round_player, :with_score_six, missed_penalty: 1) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(5)
      end
    end

    context 'with score and failed penalty' do
      let(:round_player) { create(:round_player, :with_score_six, failed_penalty: 1) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(4)
      end
    end

    context 'with score and own goals' do
      let(:round_player) { create(:round_player, :with_score_six, own_goals: 1) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(4)
      end
    end

    context 'with score and cards' do
      let(:round_player) { create(:round_player, :with_score_six, yellow_card: true, red_card: true) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(3.5)
      end
    end

    context 'with score and cards for Por player' do
      let(:round_player) { create(:round_player, :with_score_six, :with_pos_por, yellow_card: true, red_card: true) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(2.5)
      end
    end

    context 'with score, bonuses and maluses' do
      let(:round_player) { create(:round_player, :with_score_six, yellow_card: true, failed_penalty: 1, goals: 2, assists: 1) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(10.5)
      end
    end

    context 'with score and won penalty' do
      let(:round_player) { create(:round_player, :with_score_six, penalties_won: 1) }

      it 'returns score with bonus' do
        expect(round_player.result_score).to eq(7)
      end
    end

    context 'with score and conceded penalty' do
      let(:round_player) { create(:round_player, :with_score_six, conceded_penalty: 2) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(4)
      end
    end

    context 'with score, cleansheet and Por position' do
      let(:round_player) { create(:round_player, :with_score_six, :with_pos_por, cleansheet: true) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(7.5)
      end
    end

    context 'with score, cleansheet and Dc position' do
      let(:round_player) { create(:round_player, :with_score_six, :with_pos_dc, cleansheet: true) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(7)
      end
    end

    context 'with score, cleansheet and E position' do
      let(:round_player) { create(:round_player, :with_score_six, :with_pos_e, cleansheet: true) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(6.5)
      end
    end

    context 'with score, cleansheet and M position' do
      let(:round_player) { create(:round_player, :with_score_six, :with_pos_m, cleansheet: true) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(6.5)
      end
    end

    context 'with score, cleansheet and С position' do
      let(:round_player) { create(:round_player, :with_score_six, :with_pos_c, cleansheet: true) }

      it 'returns score with malus' do
        expect(round_player.result_score).to eq(6)
      end
    end
  end

  describe '#club_played_match?' do
    context 'without tournament match result' do
      it 'returns false' do
        expect(round_player.club_played_match?).to be(false)
      end
    end

    context 'with not played tournament match' do
      let(:round_player) { create(:round_player, :with_tournament_match) }

      it 'returns false' do
        expect(round_player.club_played_match?).to be(false)
      end
    end

    context 'with finished tournament match' do
      let(:round_player) { create(:round_player, :with_finished_t_match) }

      it 'returns true' do
        expect(round_player.club_played_match?).to be(true)
      end
    end
  end

  describe '#another_tournament?' do
    context 'with active club' do
      it 'returns true' do
        expect(round_player.another_tournament?).to be(false)
      end
    end

    context 'with archived club' do
      let(:player) { create(:player, club: create(:archived_club)) }
      let(:round_player) { create(:round_player, player: player) }

      it 'returns true' do
        expect(round_player.another_tournament?).to be(true)
      end
    end

    context 'when player moved to another tournament' do
      let(:club) { create(:club, tournament: Tournament.last) }
      let(:round_player) { create(:round_player) }

      before do
        round_player.player.update(club: club)
      end

      it 'returns true' do
        expect(round_player.another_tournament?).to be(true)
      end
    end
  end

  describe '#appearances' do
    context 'without match players' do
      it 'returns zero' do
        expect(round_player.appearances).to eq(0)
      end
    end

    context 'with match players' do
      it 'returns match players count' do
        create_list(:match_player, 3, round_player: round_player)
        expect(round_player.appearances).to eq(3)
      end
    end
  end
end

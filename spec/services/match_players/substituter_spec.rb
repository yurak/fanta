RSpec.describe MatchPlayers::Substituter do
  describe '#call' do
    subject(:substituter) { described_class.new(out_mp_id: main_player_id, in_mp_id: reserve_player_id) }

    let(:main_player) { create(:dc_match_player, cleansheet: true, position_malus: -3) }
    let(:reserve_player) { create(:match_player, round_player: create(:round_player, :with_pos_dc), cleansheet: true) }
    let(:main_player_id) { main_player.id }
    let(:reserve_player_id) { reserve_player.id }

    context 'without existing match_players' do
      let(:main_player_id) { '' }
      let(:reserve_player_id) { '' }

      it { expect(substituter.call).to eq(false) }
    end

    context 'without existing main match_player' do
      let(:main_player_id) { '' }

      it { expect(substituter.call).to eq(false) }
    end

    context 'without existing reserve match_player' do
      let(:reserve_player_id) { '' }

      it { expect(substituter.call).to eq(false) }
    end

    context 'with incompatible positions' do
      let(:main_player) { create(:w_match_player) }

      it { expect(substituter.call).to eq(false) }
    end

    context 'with valid params' do
      before do
        substituter.call
      end

      it { expect(main_player.reload.round_player).to eq(reserve_player.round_player) }
      it { expect(reserve_player.reload.round_player).to eq(main_player.round_player) }
      it { expect(main_player.reload.subs_status).to eq('get_in') }
      it { expect(reserve_player.reload.subs_status).to eq('get_out') }
      it { expect(main_player.reload.cleansheet).to eq(false) }
      it { expect(reserve_player.reload.cleansheet).to eq(false) }
      it { expect(main_player.reload.position_malus).to eq(0) }
      it { expect(reserve_player.reload.position_malus).to eq(0) }
      it { expect(substituter.call).to eq(true) }
    end
  end
end

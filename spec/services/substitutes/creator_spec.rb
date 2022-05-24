RSpec.describe Substitutes::Creator do
  describe '#call' do
    subject(:creator) { described_class.new(out_mp_id: main_player_id, in_mp_id: reserve_player_id) }

    let(:main_player) { create(:dc_match_player, position_malus: -3) }
    let(:reserve_player) { create(:match_player, round_player: create(:round_player, :with_pos_dc)) }
    let(:main_player_id) { main_player.id }
    let(:reserve_player_id) { reserve_player.id }

    context 'without existing match_players' do
      let(:main_player_id) { '' }
      let(:reserve_player_id) { '' }

      it { expect(creator.call).to be(false) }
    end

    context 'without existing main match_player' do
      let(:main_player_id) { '' }

      it { expect(creator.call).to be(false) }
    end

    context 'without existing reserve match_player' do
      let(:reserve_player_id) { '' }

      it { expect(creator.call).to be(false) }
    end

    context 'with incompatible positions' do
      let(:main_player) { create(:w_match_player) }

      it { expect(creator.call).to be(false) }
    end

    context 'with valid params' do
      before do
        creator.call
      end

      it { expect(main_player.reload.round_player).to eq(reserve_player.round_player) }
      it { expect(reserve_player.reload.round_player).to eq(main_player.round_player) }
      it { expect(main_player.reload.subs_status).to eq('get_in') }
      it { expect(reserve_player.reload.subs_status).to eq('get_out') }
      it { expect(main_player.reload.position_malus).to eq(0) }
      it { expect(reserve_player.reload.position_malus).to eq(0) }
      it { expect(creator.call).to be(true) }
      it { expect(Substitute.last.main_mp).to eq(main_player) }
      it { expect(Substitute.last.reserve_mp).to eq(reserve_player) }
      it { expect(Substitute.last.out_rp).to eq(main_player.round_player) }
      it { expect(Substitute.last.in_rp).to eq(reserve_player.round_player) }
    end
  end
end

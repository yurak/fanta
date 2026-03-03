RSpec.describe Scores::PositionMalus::Updater do
  describe '#call' do
    let(:tour) { create(:tour) }
    let(:lineup) { create(:lineup, tour: tour) }

    context 'when player plays in native position' do
      let!(:match_player) { create(:dc_match_player, lineup: lineup) }

      it 'does not update position_malus' do
        expect { described_class.call(tour) }.not_to(change { match_player.reload.position_malus })
      end
    end

    context 'when player plays outside native position' do
      let!(:match_player) do
        rp = create(:round_player, :with_pos_dc, :with_score_six)
        create(:match_player, lineup: lineup, round_player: rp, real_position: 'Dd')
      end

      it 'updates position_malus with the calculated malus' do
        described_class.call(tour)

        expect(match_player.reload.position_malus).to eq(Position::S_MALUS)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Substitutes::AutoBot do
  subject(:auto_bot) { described_class.new(match_lineup, preview: preview) }

  let(:match_lineup) { create(:lineup) }
  let(:preview) { true }
  let(:pc_sub) { create(:pc_match_player, lineup: match_lineup, real_position: nil) }
  let(:pc_one) { create(:pc_match_player, lineup: match_lineup) }

  before do
    match_lineup.tour.locked!
    create(:por_match_player, lineup: match_lineup)
    create(:dc_match_player, position_malus: -3, lineup: match_lineup)
    create(:dc_match_player, position_malus: -3, lineup: match_lineup)
    create(:dc_match_player, position_malus: -3, lineup: match_lineup)
    create(:e_match_player, position_malus: -3, lineup: match_lineup)
    create(:e_match_player, position_malus: -3, lineup: match_lineup)
    create(:m_match_player, position_malus: -3, lineup: match_lineup)
    create(:c_match_player, position_malus: -3, lineup: match_lineup)
    create(:c_match_player, position_malus: -3, lineup: match_lineup)

    pc_one.round_player.update(score: 0)
    rp = pc_one.round_player
    create(
      :tournament_match,
      host_club_id: rp.club.id,
      guest_club_id: rp.club.id,
      tournament_round: rp.tournament_round,
      host_score: 2,
      guest_score: 0
    )
    create(:pc_match_player, position_malus: -3, lineup: match_lineup)
    create(:pc_match_player, position_malus: -3, lineup: match_lineup)
    rp_sub = pc_sub.round_player
    rp_sub.update(score: 6.0)
    create(
      :tournament_match,
      host_club_id: rp_sub.club.id,
      guest_club_id: rp_sub.club.id,
      tournament_round: rp_sub.tournament_round,
      host_score: 2,
      guest_score: 0
    )
  end

  describe '#team_with_zero_maluses' do
    context 'with preview: true' do
      it 'returns proper team' do
        expect(auto_bot.team_with_zero_maluses).to eq({ pc_one.id => { 0 => [pc_sub.id] } })
      end
    end
  end

  describe '#process' do
    context 'with preview: true' do
      before do
        auto_bot.process
      end

      let(:expected) do
        [
          { 'in' => pc_sub.player.full_name_with_positions, 'out' => pc_one.player.full_name_with_positions }
        ]
      end

      it 'updates lineups substitutes' do
        expect(match_lineup.substitutes_preview).to eq(expected)
      end
    end
  end
end

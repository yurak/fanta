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

  describe '#call' do
    context 'with preview: true' do
      before { auto_bot.call }

      it 'saves substitutes preview on the lineup' do
        expected = [{ 'in' => pc_sub.player.full_name_with_positions,
                      'out' => pc_one.player.full_name_with_positions }]
        expect(match_lineup.substitutes_preview).to eq(expected)
      end

      it 'does not create Substitute records' do
        expect(Substitute.count).to eq(0)
      end
    end

    context 'with preview: false' do
      let(:preview) { false }

      it 'creates a Substitute record' do
        expect { auto_bot.call }.to change(Substitute, :count).by(1)
      end

      it 'marks the out player as get_in' do
        auto_bot.call
        expect(pc_one.reload.subs_status).to eq('get_in')
      end

      it 'marks the bench player as get_out' do
        auto_bot.call
        expect(pc_sub.reload.subs_status).to eq('get_out')
      end

      it 'does not update the lineup substitutes preview' do
        auto_bot.call
        expect(match_lineup.reload.substitutes).to be_nil
      end
    end

    context 'when no main player needs substitution' do
      before { pc_one.round_player.update(score: 7.0) }

      it 'returns an empty array' do
        expect(described_class.call(match_lineup, preview: preview)).to eq([])
      end

      it 'does not create Substitute records' do
        auto_bot.call
        expect(Substitute.count).to eq(0)
      end
    end

    context 'when no bench player has a score' do
      before { pc_sub.round_player.update(score: 0) }

      it 'returns an empty array' do
        expect(described_class.call(match_lineup, preview: preview)).to eq([])
      end

      it 'does not create Substitute records' do
        auto_bot.call
        expect(Substitute.count).to eq(0)
      end
    end

    context 'when the bench player is not_in_squad' do
      before { pc_sub.update(subs_status: :not_in_squad) }

      it 'returns an empty array' do
        expect(auto_bot.call).to eq([])
      end

      it 'does not create Substitute records' do
        described_class.new(match_lineup, preview: false).call
        expect(Substitute.count).to eq(0)
      end
    end

    context 'when the bench player has an incompatible position' do
      let(:pc_sub) { create(:por_match_player, lineup: match_lineup, real_position: nil) }

      it 'returns an empty array' do
        expect(auto_bot.call).to eq([])
      end

      it 'does not create Substitute records' do
        described_class.new(match_lineup, preview: false).call
        expect(Substitute.count).to eq(0)
      end
    end

    context 'when multiple main players need substitution' do
      let!(:e_main) { create(:e_match_player, lineup: match_lineup) }

      before do
        create(:e_match_player, lineup: match_lineup, real_position: nil)
        e_main.round_player.update(score: 0)
        rp = e_main.round_player
        create(
          :tournament_match,
          host_club_id: rp.club.id,
          guest_club_id: rp.club.id,
          tournament_round: rp.tournament_round,
          host_score: 2,
          guest_score: 0
        )
      end

      it 'creates a Substitute record for each player' do
        expect { described_class.new(match_lineup, preview: false).call }.to change(Substitute, :count).by(2)
      end

      it 'saves two entries in the substitutes preview' do
        auto_bot.call
        expect(match_lineup.substitutes_preview.size).to eq(2)
      end
    end
  end

  describe '.for_round' do
    let(:round) { create(:tournament_round) }
    let!(:tours) { create_list(:tour, 2, tournament_round: round) }

    before do
      tours.each { |t| allow(t).to receive(:autobot) }
      allow(round).to receive(:tours).and_return(tours)
    end

    it 'calls autobot on each tour' do
      described_class.for_round(round)
      expect(tours).to all(have_received(:autobot).with(preview: true))
    end

    it 'passes preview: false when specified' do
      described_class.for_round(round, preview: false)
      expect(tours).to all(have_received(:autobot).with(preview: false))
    end
  end
end

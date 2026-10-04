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
        expected = [{ 'out_mp_id' => pc_one.id, 'in_mp_id' => pc_sub.id,
                      'out' => pc_one.player.full_name_with_positions,
                      'in' => pc_sub.player.full_name_with_positions }]
        expect(match_lineup.substitutes_preview).to eq(expected)
      end

      # The plan has to carry ids, or the apply pass has nothing it can act on and falls back to
      # recomputing — which is what let it perform swaps the admin never saw.
      it 'stores the match player ids, not just the names it draws' do
        expect(match_lineup.substitutes_preview.first).to include('out_mp_id', 'in_mp_id')
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

      # Both passes leave a record now: an admin who skips the preview used to leave no trace of what
      # the autobot did beyond `Substitute.subs_by`.
      it 'records what it did on the lineup' do
        auto_bot.call
        expect(match_lineup.reload.substitutes_preview.size).to eq(1)
      end
    end

    # The whole point of two passes: the admin approves a list, and the second click carries out THAT
    # list. Scores keep arriving between the clicks, so recomputing could perform swaps nobody saw.
    context 'with a plan the admin approved' do
      let(:preview) { false }

      before { described_class.call(match_lineup, preview: true) }

      it 'uses the stored plan instead of recomputing' do
        allow(Substitutes::TieredMatcher).to receive(:call)
        auto_bot.call

        expect(Substitutes::TieredMatcher).not_to have_received(:call)
      end

      it 'makes the substitution the plan names' do
        expect { auto_bot.call }.to change(Substitute, :count).by(1)
      end

      it 'records the pair it carried out' do
        auto_bot.call

        expect(match_lineup.reload.substitutes_preview.first['in_mp_id']).to eq(pc_sub.id)
      end
    end

    context 'when the approved plan no longer holds' do
      let(:preview) { false }

      before do
        described_class.call(match_lineup, preview: true)
        # the reserve is gone from the lineup, so his half of the plan cannot be carried out
        pc_sub.destroy
      end

      it 'makes no substitution' do
        expect { auto_bot.call }.not_to change(Substitute, :count)
      end

      it 'says so in the log rather than dropping it in silence' do
        allow(Rails.logger).to receive(:warn)
        auto_bot.call

        expect(Rails.logger).to have_received(:warn).with(/\[autobot\] skipped/)
      end
    end

    # A plan written before the column carried ids cannot be applied, so it must be recomputed.
    context 'with a legacy plan that has no ids' do
      let(:preview) { false }

      before { match_lineup.update(substitutes: [{ 'out' => 'Someone', 'in' => 'Another' }].to_json) }

      it 'falls back to computing the pairs' do
        expect { auto_bot.call }.to change(Substitute, :count).by(1)
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

    # The plan used to survive a regeneration: a lineup that no longer needed anyone was skipped
    # before the write, so the page kept showing pairs that would never be made.
    context 'when a stored plan is no longer needed' do
      before do
        described_class.call(match_lineup, preview: true)
        pc_one.round_player.update(score: 7.0)
      end

      it 'clears the plan instead of leaving the old one on screen' do
        described_class.call(match_lineup, preview: true)

        expect(match_lineup.reload.substitutes_preview).to eq([])
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

    context 'with two equal-malus bench candidates' do
      let!(:second_bench) do
        mp = create(:pc_match_player, lineup: match_lineup, real_position: nil)
        rp = mp.round_player
        rp.update(score: 6.0)
        create(
          :tournament_match,
          host_club_id: rp.club.id,
          guest_club_id: rp.club.id,
          tournament_round: rp.tournament_round,
          host_score: 2,
          guest_score: 0
        )
        mp
      end

      before do
        # Feed the service the bench in reverse-id order; it must still pick the lowest-id bench.
        allow(match_lineup).to receive(:match_players)
          .and_return(MatchPlayer.where(lineup: match_lineup).order(id: :desc))
        auto_bot.call
      end

      it 'places the tie-break candidate lower in the bench (higher id)' do
        expect(pc_sub.id).to be < second_bench.id
      end

      it 'substitutes the bench player that is higher in the list (lowest id)' do
        expect(match_lineup.substitutes_preview.first['in']).to eq(pc_sub.player.full_name_with_positions)
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
      # what a tour really answers: one entry per lineup, each the pairs made for it
      tours.each { |t| allow(t).to receive(:autobot).and_return([[{}, {}], []]) }
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

    it 'counts the lineups it went through' do
      expect(described_class.for_round(round)[:lineups]).to eq(4)
    end

    it 'counts the substitutions made' do
      expect(described_class.for_round(round)[:substitutes]).to eq(4)
    end

    it 'reports no failures when every tour went through' do
      expect(described_class.for_round(round)[:failures]).to be_empty
    end

    context 'when one tour blows up' do
      before { allow(tours.first).to receive(:autobot).and_raise(ActiveRecord::RecordInvalid) }

      it 'still runs the rest of the round' do
        expect(described_class.for_round(round)[:lineups]).to eq(2)
      end

      it 'names the tour that failed' do
        expect(described_class.for_round(round)[:failures].first).to include("tour #{tours.first.id}")
      end
    end
  end
end

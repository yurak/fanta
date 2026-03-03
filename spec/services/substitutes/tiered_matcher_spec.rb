RSpec.describe Substitutes::TieredMatcher do
  subject(:result) { described_class.call(grid) }

  context 'when grid is empty' do
    let(:grid) { [] }

    it { is_expected.to eq([[], 0.0]) }
  end

  context 'when all cells are incompatible' do
    let(:grid) { [%w[X X], %w[X X]] }

    it { is_expected.to eq([[], 0.0]) }
  end

  context 'with tier 0 (no malus)' do
    context 'with a simple match' do
      let(:grid) { [[0]] }

      it { is_expected.to eq([[[0, 0, 0.0]], 0.0]) }
    end

    context 'when augmenting path is needed' do
      # mp1 (DM/CM) can sub with bp1 (CM) or bp2 (DM) — both malus 0
      # mp2 (CM) can only sub with bp1 (CM) — malus 0, or bp2 (DM) — malus 1.5
      # Greedy would assign mp1→bp1 and leave mp2 with malus 1.5
      # TieredMatcher reassigns mp1→bp2 (still 0) to free bp1 for mp2
      let(:grid) { [[0, 0], [0, 1.5]] }

      it 'assigns zero total malus' do
        _, total = result
        expect(total).to eq(0.0)
      end

      it 'matches each player to a unique bench player' do
        assignments, = result
        expect(assignments).to contain_exactly([0, 1, 0.0], [1, 0, 0.0])
      end
    end

    context 'when only one bench player is available for two main players' do
      let(:grid) { [[0], [0]] }

      it 'matches only one player' do
        assignments, = result
        expect(assignments.size).to eq(1)
      end

      it 'assigns zero total malus' do
        _, total = result
        expect(total).to eq(0.0)
      end
    end
  end

  context 'with tier 1.5' do
    context 'when no tier 0 option exists' do
      let(:grid) { [[1.5]] }

      it { is_expected.to eq([[[0, 0, 1.5]], 1.5]) }
    end

    context 'when augmenting path is needed within tier 1.5' do
      let(:grid) { [[1.5, 1.5], [1.5, 3.0]] }

      it 'assigns 1.5 malus to both players' do
        assignments, = result
        expect(assignments.map { |_, _, v| v }).to all(eq(1.5))
      end

      it 'returns total malus of 3.0' do
        _, total = result
        expect(total).to eq(3.0)
      end
    end

    context 'when a bench player matched in tier 0 cannot be stolen by tier 1.5' do
      let(:grid) { [[0], [1.5]] }

      it 'returns the tier 0 assignment only' do
        assignments, = result
        expect(assignments).to eq([[0, 0, 0.0]])
      end

      it 'returns zero total malus' do
        _, total = result
        expect(total).to eq(0.0)
      end
    end
  end

  context 'with tier 3.0' do
    context 'when no tier 0 or 1.5 option exists' do
      let(:grid) { [[3.0]] }

      it { is_expected.to eq([[[0, 0, 3.0]], 3.0]) }
    end

    context 'when a bench player matched in tier 0 cannot be stolen by tier 3.0' do
      let(:grid) { [[0], [3.0]] }

      it 'returns the tier 0 assignment only' do
        assignments, = result
        expect(assignments).to eq([[0, 0, 0.0]])
      end

      it 'returns zero total malus' do
        _, total = result
        expect(total).to eq(0.0)
      end
    end
  end

  context 'when a tier-0 matched column can be freed by escaping to another tier-0 column' do
    # Module 4-4-1-1 real case:
    #              col0(Dc/Dd)  col1(Dc)  col2(W/A)
    # row0(Dc):         0          0         X      — two native options
    # row1(E):         3.0         X        3.0     — no native option, all M_MALUS
    # row2(E/W):       3.0         X         0      — W is native
    #
    # Tier-0 matches row0→col0, row2→col2 and locks them.
    # row1(E) is left unmatched because both its options (col0, col2) are locked.
    # row0(Dc) can escape to col1 (also 0 malus), freeing col0 for row1(E).
    let(:grid) do
      [
        [0, 0, 'X'],
        [3.0, 'X', 3.0],
        [3.0, 'X', 0]
      ]
    end

    it 'matches all three rows' do
      assignments, = result
      expect(assignments.size).to eq(3)
    end

    it 'assigns the E row via freed column' do
      assignments, = result
      expect(assignments).to include([1, 0, 3.0])
    end

    it 'returns total malus of 3.0' do
      _, total = result
      expect(total).to eq(3.0)
    end
  end

  context 'when two rows share the only tier-0 column and one can escape to tier 1.5' do
    # Module 4-4-1-1 real case:
    #            Timber(C)  Enciso(T,A)  Gboho(W)
    # Bouaddi(C):    0         3.0          X     — Timber is native
    # Gouiri(T/A):  3.0         0          1.5    — Enciso is native (T∩[T,A]), Gboho has S_MALUS
    # Ramos(A/Pc):   X          0          3.0    — Enciso is native (A∩[T,A])
    #
    # Greedy tier-0 assigns Gouiri→Enciso, leaving Ramos with Gboho (3.0). Total = 3.0.
    # Correct: Gouiri escapes to Gboho (1.5), freeing Enciso for Ramos (0). Total = 1.5.
    let(:grid) do
      [
        [0, 3.0, 'X'],
        [3.0, 0, 1.5],
        ['X', 0, 3.0]
      ]
    end

    it 'assigns the third row to the shared tier-0 column' do
      assignments, = result
      expect(assignments).to include([2, 1, 0.0])
    end

    it 'returns minimum total malus of 1.5' do
      _, total = result
      expect(total).to eq(1.5)
    end
  end

  context 'when E/W, T/A, A/Pc compete for A, C, W/A bench players' do
    # Module 4-4-1-1 real case:
    #              col0(A)  col1(C)  col2(W/A)
    # row0(E/W):    3.0      1.5       0       — W is native (col2), C has S_MALUS
    # row1(T/A):     0       3.0       0       — A and W/A are native
    # row2(A/Pc):    0        X        0       — A and W/A are native, C incompatible
    #
    # Tier-0 greedy takes E/W→col2, T/A→col0. A/Pc displaces T/A to col1 (M_MALUS).
    # 2-opt improvement swaps E/W↔T/A: E/W→col1 (S_MALUS), T/A→col2 (native). Total = 1.5.
    let(:grid) do
      [
        [3.0, 1.5, 0],
        [0, 3.0, 0],
        [0, 'X', 0]
      ]
    end

    it 'matches all three rows' do
      assignments, = result
      expect(assignments.size).to eq(3)
    end

    it 'assigns E/W to the C bench player after 2-opt improvement' do
      assignments, = result
      expect(assignments).to include([0, 1, 1.5])
    end

    it 'returns minimum total malus of 1.5' do
      _, total = result
      expect(total).to eq(1.5)
    end
  end

  context 'with mixed tiers across different rows' do
    let(:grid) { [[0, 'X'], ['X', 3.0]] }

    it 'matches each player in their respective tier' do
      assignments, = result
      expect(assignments).to contain_exactly([0, 0, 0.0], [1, 1, 3.0])
    end

    it 'returns correct total malus' do
      _, total = result
      expect(total).to eq(3.0)
    end
  end

  context 'when a non-native row steals the only slot from a native row' do
    # Dd (row0) can sub Dc(bench) only with 1.5 malus, M(bench) is incompatible
    # Dc (row1) can sub Dc(bench) natively (0 malus)
    # Current greedy: Dd→Dc(bench)(1.5), Dc unmatched  ← WRONG
    # Expected: Dc→Dc(bench)(0), Dd unmatched            ← 1 zero-malus sub wins
    let(:grid) do
      [
        [1.5, 'X'],  # Dd: Dc(bench)=1.5, M(bench)=X
        [0,   'X']   # Dc: Dc(bench)=0,   M(bench)=X
      ]
    end

    it 'performs exactly one zero-malus substitution' do
      assignments, = result
      expect(assignments).to eq([[1, 0, 0.0]])
    end

    it 'returns zero total malus' do
      _, total = result
      expect(total).to eq(0.0)
    end
  end

  context 'when a non-native row steals a slot but another slot is available for it' do
    # Dd (row0): Dc(bench)=1.5, M(bench)=3.0
    # Dc (row1): Dc(bench)=0,   M(bench)=X
    # Expected: Dc→Dc(bench)(0) [zero-malus first], Dd→M(bench)(3.0) [remaining slot]
    let(:grid) do
      [
        [1.5, 3.0],  # Dd: both bench players substitutable with malus
        [0,   'X']   # Dc: only Dc(bench) natively
      ]
    end

    it 'performs both substitutions' do
      assignments, = result
      expect(assignments.size).to eq(2)
    end

    it 'assigns Dc to the zero-malus slot' do
      assignments, = result
      expect(assignments).to include([1, 0, 0.0])
    end

    it 'assigns Dd to the remaining slot with malus' do
      assignments, = result
      expect(assignments).to include([0, 1, 3.0])
    end

    it 'returns total malus of 3.0' do
      _, total = result
      expect(total).to eq(3.0)
    end
  end

  context 'when M and C did not play, bench has T and M/C' do
    # M  (row0): T(bench)=X (T cannot cover M), M/C(bench)=0 (native)
    # C  (row1): T(bench)=3.0 (M_MALUS),        M/C(bench)=0 (native)
    # Both compete for the single zero-malus slot (M/C bench).
    # M has no alternative: if M/C goes to C, M is unmatched → only 1 sub total.
    # Correct: M→M/C(0) [native, frees T for C], C→T(3.0) → 2 subs, 1 zero-malus.
    let(:grid) do
      [
        ['X', 0],  # M: T(bench)=X, M/C(bench)=0
        [3.0, 0]   # C: T(bench)=3.0, M/C(bench)=0
      ]
    end

    it 'matches both players' do
      assignments, = result
      expect(assignments.size).to eq(2)
    end

    it 'assigns M natively to M/C bench (zero-malus)' do
      assignments, = result
      expect(assignments).to include([0, 1, 0.0])
    end

    it 'assigns C to T bench with 3.0 malus' do
      assignments, = result
      expect(assignments).to include([1, 0, 3.0])
    end

    it 'returns total malus of 3.0' do
      _, total = result
      expect(total).to eq(3.0)
    end
  end
end

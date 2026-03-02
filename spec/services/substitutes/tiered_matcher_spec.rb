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
end

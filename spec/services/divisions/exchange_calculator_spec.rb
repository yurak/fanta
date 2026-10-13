RSpec.describe Divisions::ExchangeCalculator do
  subject(:rows) { described_class.call(tournament, season) }

  let(:tournament) { create(:tournament) }
  let(:season) { create(:season) }

  # one league per entry, e.g. pyramid('A' => 1, 'B' => 2) builds A1 over B1 and B2
  def pyramid(shape)
    shape.each do |level, count|
      count.times do |index|
        division = create(:division, level: level, number: index + 1)
        create(:league, tournament: tournament, season: season, division: division)
      end
    end
  end

  def row(level)
    rows.find { |candidate| candidate.level == level }
  end

  context 'with a single level' do
    before { pyramid('A' => 3) }

    # the first season of a competition, before anybody is split into divisions
    it 'returns nothing to exchange' do
      expect(rows).to be_empty
    end
  end

  context 'with one league over two' do
    before { pyramid('A' => 1, 'B' => 2) }

    it 'sends nobody up from the top' do
      expect(row('A').promotion).to eq(0)
    end

    it 'sends nobody down from the bottom' do
      expect(row('B').relegation).to eq(0)
    end

    it 'promotes two from each league below' do
      expect(row('B').promotion).to eq(2)
    end

    it 'relegates as many as the level below sends up' do
      expect(row('A').relegation).to eq(4)
    end
  end

  context 'with levels of the same width' do
    before { pyramid('A' => 2, 'B' => 2) }

    it 'exchanges three' do
      expect([row('B').promotion, row('A').relegation]).to eq([3, 3])
    end
  end

  context 'when two per league would leave a fraction' do
    before { pyramid('A' => 3, 'B' => 4) }

    # 2 * 4 / 3 is not a whole number of teams, so the exchange steps up to three
    it 'promotes three instead' do
      expect([row('B').promotion, row('A').relegation]).to eq([3, 4])
    end
  end

  context 'with a bottom tier too narrow to balance' do
    before { pyramid('A' => 1, 'B' => 9, 'C' => 1) }

    it 'falls back to the standard relegation' do
      expect(row('B').relegation).to eq(described_class::UNBALANCED_RELEGATION)
    end

    it 'flags the level as unbalanced' do
      expect(row('B').balanced).to be(false)
    end

    it 'leaves the balanced levels marked as such' do
      expect(row('A').balanced).to be(true)
    end
  end

  describe 'the slot conservation law' do
    before { pyramid('A' => 2, 'B' => 4, 'C' => 6) }

    it 'vacates exactly as many places as are filled from below' do
      aggregate_failures do
        expect(row('A').relegation * 2).to eq(row('B').promotion * 4)
        expect(row('B').relegation * 4).to eq(row('C').promotion * 6)
      end
    end
  end

  describe 'persistence' do
    before { pyramid('A' => 1, 'B' => 2) }

    it 'writes nothing by default' do
      described_class.call(tournament, season)

      expect(League.where(tournament: tournament).pluck(:promotion, :relegation).uniq).to eq([[0, 0]])
    end

    it 'stores both columns when asked to apply' do
      described_class.call(tournament, season, apply: true)

      top = League.joins(:division).find_by(divisions: { level: 'A' })
      expect([top.promotion, top.relegation]).to eq([0, 4])
    end

    # leagues keep being created mid-season, so the numbers have to be re-derivable at any point
    context 'when a league is added to the bottom level afterwards' do
      before do
        described_class.call(tournament, season, apply: true)
        create(:league, tournament: tournament, season: season,
                        division: create(:division, level: 'B', number: 3))
        described_class.call(tournament, season, apply: true)
      end

      it 'rebalances against the wider level' do
        top = League.joins(:division).find_by(divisions: { level: 'A' })

        expect([top.promotion, top.relegation]).to eq([0, 6])
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Scores::ScrapeBudget do
  subject(:budget) { described_class.new(limit: 10) }

  describe '#take' do
    it 'grants the full backoff while the budget lasts' do
      expect(budget.take(4)).to eq(4)
    end

    it 'tracks what was spent' do
      budget.take(4)

      expect(budget.spent).to eq(4)
    end

    it 'never grants more than what is left' do
      budget.take(8)

      expect(budget.take(30)).to eq(2)
    end

    it 'grants nothing once the budget is spent' do
      budget.take(10)

      expect(budget.take(5)).to eq(0)
    end

    it 'does not spend past the limit' do
      budget.take(8)
      budget.take(30)

      expect(budget.spent).to eq(10)
    end
  end

  describe '#exhausted?' do
    it { expect(budget).not_to be_exhausted }

    it 'is exhausted after the limit is spent' do
      budget.take(10)

      expect(budget).to be_exhausted
    end
  end

  describe 'the default limit' do
    it 'caps a run well inside the five-minute live cron interval' do
      expect(described_class::DEFAULT_LIMIT).to be < 5.minutes
    end
  end
end

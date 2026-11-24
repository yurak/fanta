require 'rails_helper'

RSpec.describe Scores::ScrapeBudget do
  subject(:budget) { described_class.new(limit: 10, sleeper: sleeper) }

  let(:sleeper) { class_double(Kernel, sleep: nil) }

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

  describe '#wait' do
    it 'sleeps for what the budget granted' do
      budget.wait(4)

      expect(sleeper).to have_received(:sleep).with(4)
    end

    it 'reports how long it slept' do
      expect(budget.wait(4)).to eq(4)
    end

    it 'sleeps only for what is left' do
      budget.take(8)
      budget.wait(30)

      expect(sleeper).to have_received(:sleep).with(2)
    end

    it 'does not sleep once the budget is spent' do
      budget.take(10)
      budget.wait(5)

      expect(sleeper).not_to have_received(:sleep)
    end

    it 'reports nothing slept once the budget is spent' do
      budget.take(10)

      expect(budget.wait(5)).to eq(0)
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

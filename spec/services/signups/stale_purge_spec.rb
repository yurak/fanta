require 'rails_helper'

RSpec.describe Signups::StalePurge do
  subject(:purge) { described_class.new(days: 30) }

  let!(:stale) { create(:user, confirmed_at: nil, created_at: 60.days.ago) }

  describe 'what it picks up' do
    it 'finds an old sign-up that was never confirmed' do
      expect(purge.removable).to contain_exactly(stale)
    end

    # the link never expires here, so a recent sign-up may still be a person who has not read
    # their mail yet
    it 'leaves a recent one alone' do
      recent = create(:user, confirmed_at: nil, created_at: 3.days.ago)

      expect(purge.removable).not_to include(recent)
    end

    it 'counts the recent ones so the report says what was spared' do
      create(:user, confirmed_at: nil, created_at: 3.days.ago)

      expect(purge.newer_count).to eq(1)
    end

    it 'leaves a confirmed account alone however old' do
      confirmed = create(:user, confirmed_at: 100.days.ago, created_at: 200.days.ago)

      expect(purge.removable).not_to include(confirmed)
    end
  end

  # The emptiness test is what keeps this from deleting a real person who simply never confirmed.
  describe 'an old sign-up that owns something' do
    let!(:busy) { create(:user, confirmed_at: nil, created_at: 60.days.ago) }

    before { create(:team, user: busy) }

    it 'is not removable' do
      expect(purge.removable).not_to include(busy)
    end

    it 'is reported as kept' do
      expect(purge.kept).to contain_exactly(busy)
    end

    it 'survives the purge' do
      purge.purge!

      expect(busy.reload).to be_present
    end
  end

  describe 'a sign-up that only reached the Telegram step' do
    let!(:with_profile) { create(:user, confirmed_at: nil, created_at: 60.days.ago) }

    before { create(:user_profile, user: with_profile) }

    it 'counts as not empty' do
      expect(purge.removable).not_to include(with_profile)
    end
  end

  describe '#purge!' do
    it 'reports how many went' do
      expect(purge.purge!).to eq(1)
    end

    it 'removes them' do
      expect { purge.purge! }.to change(User, :count).by(-1)
    end

    it 'is safe to run twice' do
      purge.purge!

      expect(described_class.new(days: 30).purge!).to eq(0)
    end
  end

  describe 'the default age' do
    it 'is a month, which is long after anyone would confirm' do
      expect(described_class::DEFAULT_DAYS).to eq(30)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# rubocop:disable RSpec/DescribeClass, RSpec/BeforeAfterAll
RSpec.describe 'tg:send_auction_round_deadline' do
  subject(:run_task) { Rake::Task['tg:send_auction_round_deadline'].invoke }

  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('tg:send_auction_round_deadline')
  end

  before { allow(Notifications::Creator).to receive(:call) }

  after { Rake::Task['tg:send_auction_round_deadline'].reenable }

  let!(:league) { create(:active_league) }
  let!(:auction) { create(:auction, league: league) }
  # 165 minutes = 2h45m — within the 2.5–3h window
  let!(:round) { create(:auction_round, auction: auction, status: :active, deadline: 165.minutes.from_now) }

  it 'creates auction_round_ddl notification with the AuctionRound as notifiable' do
    run_task

    expect(Notifications::Creator).to have_received(:call)
      .with(notifiable: round, kind: :auction_round_ddl)
  end

  it 'does not pass the Auction as notifiable (regression)' do
    run_task

    expect(Notifications::Creator).not_to have_received(:call)
      .with(notifiable: auction, kind: :auction_round_ddl)
  end

  it 'does not raise NoMethodError on Auction (regression)' do
    expect { run_task }.not_to raise_error
  end

  context 'when deadline is more than 3 hours away' do
    # overrides let!(:round) — outer before { round } resolves to this definition
    let(:round) { create(:auction_round, auction: auction, status: :active, deadline: 4.hours.from_now) }

    it 'does not create a notification' do
      run_task

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when deadline is less than 2.5 hours away' do
    let(:round) { create(:auction_round, auction: auction, status: :active, deadline: 2.hours.from_now) }

    it 'does not create a notification' do
      run_task

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when round has no deadline' do
    let(:round) { create(:auction_round, auction: auction, status: :active, deadline: nil) }

    it 'does not create a notification' do
      run_task

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when league is not active' do
    # overrides let!(:league) — outer before { league } resolves to this inactive league
    let(:league) { create(:league) }

    it 'does not create a notification' do
      run_task

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when round is not active' do
    let(:round) { create(:closed_auction_round, auction: auction, deadline: 165.minutes.from_now) }

    it 'does not create a notification' do
      run_task

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/BeforeAfterAll

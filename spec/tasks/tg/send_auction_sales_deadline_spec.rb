# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# rubocop:disable RSpec/DescribeClass, RSpec/BeforeAfterAll
RSpec.describe 'tg:send_auction_sales_deadline' do
  subject(:run_task) { Rake::Task['tg:send_auction_sales_deadline'].invoke }

  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?('tg:send_auction_sales_deadline')
  end

  before { allow(Notifications::Creator).to receive(:call) }

  after { Rake::Task['tg:send_auction_sales_deadline'].reenable }

  let!(:league) { create(:active_league) }
  let!(:auction) { create(:auction, league: league, status: :sales, deadline: 10.hours.from_now) }

  it 'creates auction_sales_ddl notification via Notifications::Creator' do
    run_task

    expect(Notifications::Creator).to have_received(:call)
      .with(notifiable: auction, kind: :auction_sales_ddl)
  end

  it 'does not call the notifier class directly with an Auction (regression)' do
    expect { run_task }.not_to raise_error
  end

  context 'when deadline is more than 18 hours away' do
    # creates a second (later) auction so league.auctions.sales.last returns this one
    before { create(:auction, league: league, status: :sales, deadline: 20.hours.from_now) }

    it 'does not create a notification' do
      run_task

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when auction has no deadline' do
    # creates a second (later) auction so league.auctions.sales.last returns this one
    before { create(:auction, league: league, status: :sales, deadline: nil) }

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

  context 'when auction is not in sales status' do
    # overrides let!(:auction) — outer before { auction } resolves to this initial-status auction
    let(:auction) { create(:auction, league: league, status: :initial, deadline: 10.hours.from_now) }

    it 'does not create a notification' do
      run_task

      expect(Notifications::Creator).not_to have_received(:call)
    end
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/BeforeAfterAll

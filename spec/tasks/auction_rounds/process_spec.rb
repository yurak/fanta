# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'auction_rounds:process' do
  before do
    Rake.application.rake_require('tasks/auction_rounds')
    Rake::Task.define_task(:environment)
    Rake::Task['auction_rounds:process'].reenable
    allow(AuctionRounds::Manager).to receive(:call)
  end

  def run_task
    Rake::Task['auction_rounds:process'].invoke
  end

  context 'when there are no active auction rounds' do
    it 'does not call AuctionRounds::Manager' do
      run_task
      expect(AuctionRounds::Manager).not_to have_received(:call)
    end
  end

  context 'when there are active auction rounds' do
    let(:league) { create(:active_league) }
    let(:auction) { create(:auction, league: league) }
    let(:round) { create(:auction_round, auction: auction) }

    before { round }

    it 'calls AuctionRounds::Manager for each active round' do
      run_task
      expect(AuctionRounds::Manager).to have_received(:call).with(round)
    end
  end

  context 'when there are closed auction rounds' do
    let(:league) { create(:active_league) }
    let(:auction) { create(:auction, league: league) }

    before { create(:closed_auction_round, auction: auction) }

    it 'does not call AuctionRounds::Manager' do
      run_task
      expect(AuctionRounds::Manager).not_to have_received(:call)
    end
  end

  # The cron tick must not stack up on a run that is still going.
  context 'when another run already holds the advisory lock' do
    let(:league) { create(:active_league) }
    let(:auction) { create(:auction, league: league) }

    before do
      create(:auction_round, auction: auction)
      allow(ActiveRecord::Base.connection).to receive(:select_value).and_call_original
      allow(ActiveRecord::Base.connection).to receive(:select_value)
        .with(/pg_try_advisory_lock/).and_return(false)
    end

    it 'skips the run' do
      run_task
      expect(AuctionRounds::Manager).not_to have_received(:call)
    end

    it 'does not release a lock it never took' do
      run_task
      expect(ActiveRecord::Base.connection).not_to have_received(:select_value).with(/pg_advisory_unlock/)
    end
  end

  context 'when the run takes the advisory lock' do
    let(:league) { create(:active_league) }
    let(:auction) { create(:auction, league: league) }

    before do
      create(:auction_round, auction: auction)
      allow(ActiveRecord::Base.connection).to receive(:select_value).and_call_original
    end

    it 'releases the lock afterwards' do
      run_task
      expect(ActiveRecord::Base.connection).to have_received(:select_value).with(/pg_advisory_unlock/)
    end
  end
end
# rubocop:enable RSpec/DescribeClass

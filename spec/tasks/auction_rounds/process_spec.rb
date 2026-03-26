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
end
# rubocop:enable RSpec/DescribeClass

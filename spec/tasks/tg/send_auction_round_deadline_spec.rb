require 'rails_helper'
require 'rake'

RSpec.describe 'tg:send_auction_round_deadline' do # rubocop:disable RSpec/DescribeClass
  before do
    Rake.application.rake_require('tasks/tg/send_auction_round_deadline')
    Rake::Task.define_task(:environment)
    Rake::Task['tg:send_auction_round_deadline'].reenable
    allow(TelegramBot::Auction::RoundDdlBroadcaster).to receive(:call)
  end

  it 'calls TelegramBot::Auction::RoundDdlBroadcaster' do
    Rake::Task['tg:send_auction_round_deadline'].invoke
    expect(TelegramBot::Auction::RoundDdlBroadcaster).to have_received(:call)
  end
end

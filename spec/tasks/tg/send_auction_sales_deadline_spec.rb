# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'tg:send_auction_sales_deadline' do
  before do
    Rake.application.rake_require('tasks/tg/send_auction_sales_deadline')
    Rake::Task.define_task(:environment)
    Rake::Task['tg:send_auction_sales_deadline'].reenable
    allow(TelegramBot::Auction::SalesDdlBroadcaster).to receive(:call)
  end

  it 'calls TelegramBot::Auction::SalesDdlBroadcaster' do
    Rake::Task['tg:send_auction_sales_deadline'].invoke
    expect(TelegramBot::Auction::SalesDdlBroadcaster).to have_received(:call)
  end
end
# rubocop:enable RSpec/DescribeClass

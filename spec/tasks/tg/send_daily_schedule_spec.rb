# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'tg:send_daily_schedule' do
  before do
    Rake.application.rake_require('tasks/tg/send_daily_schedule')
    Rake::Task.define_task(:environment)
    Rake::Task['tg:send_daily_schedule'].reenable
    allow(TelegramBot::DailyScheduleBroadcaster).to receive(:call)
  end

  it 'calls TelegramBot::DailyScheduleBroadcaster' do
    Rake::Task['tg:send_daily_schedule'].invoke
    expect(TelegramBot::DailyScheduleBroadcaster).to have_received(:call)
  end
end
# rubocop:enable RSpec/DescribeClass

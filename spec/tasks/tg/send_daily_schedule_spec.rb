# rubocop:disable RSpec/DescribeClass
require 'rails_helper'
require 'rake'

RSpec.describe 'tg:send_daily_schedule' do
  before do
    Rake.application.rake_require('tasks/tg/send_daily_schedule')
    Rake::Task.define_task(:environment)
    Rake::Task['tg:send_daily_schedule'].reenable
    allow(TelegramBot::DailyScheduleNotifier).to receive(:call)
  end

  def run_task
    Rake::Task['tg:send_daily_schedule'].invoke
  end

  def stub_hour(hour, timezone)
    allow(Time).to receive(:current).and_return(
      ActiveSupport::TimeZone[timezone].local(2026, 1, 1, hour, 45)
    )
  end

  def bot_user(time_zone)
    create(:user, :with_profile, time_zone: time_zone).tap do |u|
      u.user_profile.update!(bot_enabled: true)
    end
  end

  context 'when it is 9 AM in user timezone' do
    let!(:user) { bot_user('Kyiv') }

    before { stub_hour(9, 'Kyiv') }

    it 'calls notifier for that user' do
      run_task
      expect(TelegramBot::DailyScheduleNotifier).to have_received(:call).with(user)
    end
  end

  context 'when it is not 9 AM in user timezone' do
    before do
      bot_user('Kyiv')
      stub_hour(14, 'Kyiv')
    end

    it 'does not call notifier' do
      run_task
      expect(TelegramBot::DailyScheduleNotifier).not_to have_received(:call)
    end
  end

  context 'when user does not have bot enabled' do
    before do
      create(:user, :with_profile).tap { |u| u.user_profile.update!(bot_enabled: false) }
      stub_hour(9, 'Kyiv')
    end

    it 'does not call notifier' do
      run_task
      expect(TelegramBot::DailyScheduleNotifier).not_to have_received(:call)
    end
  end

  context 'when users are in different timezones' do
    let!(:user_kyiv)   { bot_user('Kyiv') }
    let!(:user_london) { bot_user('London') }

    # 9 AM Kyiv (UTC+2 in winter) = 7 AM London (UTC+0 in winter)
    before { stub_hour(7, 'UTC') }

    it 'calls notifier for user whose local hour is 9' do
      run_task
      expect(TelegramBot::DailyScheduleNotifier).to have_received(:call).with(user_kyiv)
    end

    it 'does not call notifier for user whose local hour is not 9' do
      run_task
      expect(TelegramBot::DailyScheduleNotifier).not_to have_received(:call).with(user_london)
    end
  end
end
# rubocop:enable RSpec/DescribeClass

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramBot::DailyScheduleBroadcaster do
  subject(:broadcaster) { described_class.new }

  before { allow(TelegramBot::DailyScheduleNotifier).to receive(:call) }

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
    let(:user) { bot_user('Kyiv') }

    before do
      user
      stub_hour(9, 'Kyiv')
    end

    it 'calls notifier for that user' do
      broadcaster.call
      expect(TelegramBot::DailyScheduleNotifier).to have_received(:call).with(user)
    end
  end

  context 'when it is not 9 AM in user timezone' do
    before do
      bot_user('Kyiv')
      stub_hour(14, 'Kyiv')
    end

    it 'does not call notifier' do
      broadcaster.call
      expect(TelegramBot::DailyScheduleNotifier).not_to have_received(:call)
    end
  end

  context 'when user does not have bot enabled' do
    before do
      create(:user, :with_profile).tap { |u| u.user_profile.update!(bot_enabled: false) }
      stub_hour(9, 'Kyiv')
    end

    it 'does not call notifier' do
      broadcaster.call
      expect(TelegramBot::DailyScheduleNotifier).not_to have_received(:call)
    end
  end

  context 'when users are in different timezones' do
    let(:user_kyiv)   { bot_user('Kyiv') }
    let(:user_london) { bot_user('London') }

    # 9 AM Kyiv (UTC+2 in winter) = 7 AM London (UTC+0 in winter)
    before do
      user_kyiv
      user_london
      stub_hour(7, 'UTC')
    end

    it 'calls notifier for user whose local hour is 9' do
      broadcaster.call
      expect(TelegramBot::DailyScheduleNotifier).to have_received(:call).with(user_kyiv)
    end

    it 'does not call notifier for user whose local hour is not 9' do
      broadcaster.call
      expect(TelegramBot::DailyScheduleNotifier).not_to have_received(:call).with(user_london)
    end
  end
end

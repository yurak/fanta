# frozen_string_literal: true

module TelegramBot
  class DailyScheduleBroadcaster < ApplicationService
    def call
      User.joins(:user_profile).where(user_profiles: { bot_enabled: true }).each do |user|
        tz = user.time_zone.presence || User::DEFAULT_TIME_ZONE
        next unless Time.current.in_time_zone(tz).hour == 9

        TelegramBot::DailyScheduleNotifier.call(user)
      end
    end
  end
end

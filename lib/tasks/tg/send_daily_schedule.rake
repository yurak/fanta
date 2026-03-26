namespace :tg do
  # rake 'tg:send_daily_schedule'
  desc 'Send daily deadline schedule notifications to users for whom it is 9 AM in their timezone'
  task send_daily_schedule: :environment do
    User.joins(:user_profile).where(user_profiles: { bot_enabled: true }).each do |user|
      tz = user.time_zone.presence || User::DEFAULT_TIME_ZONE
      next unless Time.current.in_time_zone(tz).hour == 9

      TelegramBot::DailyScheduleNotifier.call(user)
    end
  end
end

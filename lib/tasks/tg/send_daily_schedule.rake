namespace :tg do
  # rake 'tg:send_daily_schedule'
  desc 'Send daily deadline schedule notifications to users for whom it is 9 AM in their timezone'
  task send_daily_schedule: :environment do
    TelegramBot::DailyScheduleBroadcaster.call
  end
end

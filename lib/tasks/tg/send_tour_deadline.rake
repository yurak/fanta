namespace :tg do
  # rake 'tg:send_tour_deadline'
  desc 'Send notifications to Telegram about tour deadline'
  task send_tour_deadline: :environment do
    TelegramBot::Tour::DdlBroadcaster.call
  end
end

namespace :tg do
  # rake 'tg:send_auction_round_deadline'
  desc 'Send notifications to Telegram about auction round deadline'
  task send_auction_round_deadline: :environment do
    TelegramBot::Auction::RoundDdlBroadcaster.call
  end
end

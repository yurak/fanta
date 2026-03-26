namespace :tg do
  # rake 'tg:send_auction_sales_deadline'
  desc 'Send notifications to Telegram about auction sales deadline'
  task send_auction_sales_deadline: :environment do
    TelegramBot::Auction::SalesDdlBroadcaster.call
  end
end

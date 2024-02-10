namespace :tg do
  # rake 'tg:send_auction_sales_deadline'
  desc 'Send notifications to Telegram about auction sales deadline'
  task send_auction_sales_deadline: :environment do
    League.active.each do |league|
      auction = league.auctions.sales.last

      next unless auction
      next if auction.deadline.nil?
      next if DateTime.now < (auction.deadline.asctime.in_time_zone('EET') - 1.day)

      TelegramBot::AuctionSalesDdlNotifier.call(auction)
    end
  end
end

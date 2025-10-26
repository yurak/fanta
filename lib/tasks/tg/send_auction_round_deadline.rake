namespace :tg do
  # rake 'tg:send_auction_round_deadline'
  desc 'Send notifications to Telegram about auction round deadline'
  task send_auction_round_deadline: :environment do
    AuctionRound.active.each do |round|
      next unless round.auction.league.active?
      next if round.deadline.nil?
      next if DateTime.now < (round.deadline - 3.hours)
      next if DateTime.now > (round.deadline - 2.5.hours)

      TelegramBot::Auction::RoundDdlNotifier.call(round.auction)
    end
  end
end

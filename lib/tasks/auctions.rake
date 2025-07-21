namespace :auctions do
  # rake auctions:start_sales
  desc 'Start dropping phase of auctions'
  task start_sales: :environment do
    Auction.initial.each do |auction|
      next unless auction.deadline
      next if auction.primary?

      hours = ((auction.deadline - Time.zone.now) / 3_600).to_i
      next if hours > Auction::HOURS_FOR_SALES

      Auctions::Manager.call(auction, Auctions::Manager::SALES_STATUS)
    end
  end
end

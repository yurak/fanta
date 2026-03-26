namespace :auctions do
  # rake auctions:start_sales
  desc 'Start dropping phase of auctions'
  task start_sales: :environment do
    Auction.initial.each do |auction|
      Auctions::SalesOpener.call(auction)
    end
  end
end

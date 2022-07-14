namespace :auction_rounds do
  desc 'Process auction bids'
  task process: :environment do
    AuctionRound.active.each do |round|
      AuctionRounds::Manager.call(round)
    end
  end
end

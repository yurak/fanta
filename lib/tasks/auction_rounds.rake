namespace :auction_rounds do
  # rake 'auction_rounds:process'
  desc 'Process auction bids'
  task process: :environment do
    lock_key = 8_314_101

    if ActiveRecord::Base.connection.select_value("SELECT pg_try_advisory_lock(#{lock_key})")
      begin
        AuctionRound.active.each do |round|
          AuctionRounds::Manager.call(round)
        end
      ensure
        ActiveRecord::Base.connection.select_value("SELECT pg_advisory_unlock(#{lock_key})")
      end
    else
      Rails.logger.info('auction_rounds:process is already running, skipping this run')
    end
  end
end

# whenever --set 'environment=development' --update-crontab
# Lock tours by deadline
every 5.minutes do
  rake 'tours:lock_deadline'
end

# Send notifications by Telegram bot before tour deadline
every :hour do
  rake 'tg:send_tour_deadline'
end

# Send notifications by Telegram bot before auction sales deadline
every '5 9,14 * * *' do
  rake 'tg:send_auction_sales_deadline'
end

# Save messages from Telegram Bot
every '20 * * * *' do
  rake 'tg:save_messages'
end

# Sell players from teams by deadline for auctions with sales status
every 15.minutes do
  rake 'transfers:outgoing_active_league'
end

# Process auction rounds by deadline
every 10.minutes do
  rake 'auction_rounds:process'
end

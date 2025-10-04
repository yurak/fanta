# whenever --set 'environment=development' --update-crontab
# Lock tours by deadline
every 5.minutes do
  rake 'tours:lock_deadline'
end

# Auto-close tours
every '20 * * * *' do
  rake 'tours:auto_close'
end

# Auto-inject scores for moderated tours
every '55 * * * *' do
  rake 'tours:auto_inject'
end

# Send notifications by Telegram bot before tour deadline
every :hour do
  rake 'tg:send_tour_deadline'
end

# Send notifications by Telegram bot before auction sales deadline
every '25 13 * * *' do
  rake 'tg:send_auction_sales_deadline'
end

# Send notifications by Telegram bot before auction round deadline
every '5,35 * * * *' do
  rake 'tg:send_auction_round_deadline'
end

# Save messages from Telegram Bot (works only when webhooks disabled)
# every '20 * * * *' do
#   rake 'tg:save_messages'
# end

# Sell players from teams by deadline for auctions with sales status
every '1,6,11,31,36,41 * * * *' do
  rake 'transfers:outgoing_active_league'
end

# Process auction rounds by deadline
every 10.minutes do
  rake 'auction_rounds:process'
end

# Open auction dropping phase
every '15,45 * * * *' do
  rake 'auctions:start_sales'
end

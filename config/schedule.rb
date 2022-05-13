# whenever --set 'environment=development' --update-crontab
every 5.minutes do
  rake 'tours:lock_deadline'
end

every 5.minutes do
  rake 'tg:send_notifications'
end

every :hour do
  rake 'transfers:outgoing_active_league'
end

every 10.minutes do
  rake 'auction_rounds:process'
end

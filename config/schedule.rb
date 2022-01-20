# whenever --set 'environment=development' --update-crontab
every 5.minutes do
  rake 'tours:lock_deadline'
end

every :hour do
  rake 'transfers:outgoing_active_league'
end

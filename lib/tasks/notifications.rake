namespace :notifications do
  # rake 'notifications:send_pending'
  desc 'Send pending notifications in batches'
  task send_pending: :environment do
    Notifications::SendPendingJob.perform_now
  end
end

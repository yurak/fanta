namespace :clubs do
  # rake clubs:refresh
  desc 'Add new clubs'
  task refresh: :environment do
    Clubs::Creator.call
  end
end

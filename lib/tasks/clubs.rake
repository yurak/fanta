namespace :clubs do
  desc 'Add new clubs'
  task refresh: :environment do
    ClubManager.call
  end
end

namespace :clubs do
  desc 'Add new clubs'
  task refresh: :environment do
    Clubs::Creator.call
  end
end

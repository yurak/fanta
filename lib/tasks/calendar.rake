namespace :calendar do
  desc 'Create League with Teams and Tours'
  task :generate, %i[league_id tours_count add_round] => :environment do |_t, args|
    CalendarCreator.call(args[:league_id], args[:tours_count], args[:add_round])
  end
end

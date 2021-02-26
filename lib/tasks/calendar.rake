namespace :calendar do
  desc 'Create Tours, Matches and Results for League'
  task :generate, %i[league_id tours_count add_round] => :environment do |_t, args|
    CalendarCreator.call(args[:league_id], args[:tours_count], add_round: args[:add_round])
    Results::Creator.call(args[:league_id])
  end
end

namespace :calendar do
  desc 'Create Tours, Matches and Results for League'
  task :generate, %i[league_id tours_count] => :environment do |_t, args|
    ActiveRecord::Base.transaction do
      if CalendarCreator.call(args[:league_id], args[:tours_count])
        Results::Creator.call(args[:league_id])
      else
        p 'CalendarCreator Error'
      end
    end
  end
end

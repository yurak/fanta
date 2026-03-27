# rubocop:disable Metrics/BlockLength
namespace :calendar do
  # rake 'calendar:generate[303,34]'
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

  # rake 'calendar:extend_tournament[13,6]'
  desc 'Extend calendar by extra tours for all active leagues of a tournament'
  task :extend_tournament, %i[tournament_id extra_tours] => :environment do |_t, args|
    tournament_id = args[:tournament_id].to_i
    extra_tours = args[:extra_tours].to_i

    leagues = League.active.by_tournament(tournament_id)
    p "Found #{leagues.count} active leagues for tournament #{tournament_id}"

    leagues.each do |league|
      ActiveRecord::Base.transaction do
        p "Processing league #{league.id} — #{league.name}"
        if CalendarExtender.call(league.id, extra_tours)
          p "  -> OK, added #{extra_tours} tours"
        else
          p "  -> ERROR for league #{league.id}"
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

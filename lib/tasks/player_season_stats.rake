namespace :player_season_stats do
  # rake 'player_season_stats:generate'
  desc 'Generate/recalculate player season stats for all players (run once to populate existing data)'
  task generate: :environment do
    Stats::Creator.call
  end

  # rake 'player_season_stats:update_for_range[1,19999,6]'
  desc 'Generate player total stats after season'
  task :update_for_range, %i[start_id last_id season_id] => :environment do |_t, args|
    ids_range = args[:start_id].to_i..args[:last_id].to_i

    begin
      Stats::Creator.call(season_id: args[:season_id].to_i, player_ids: ids_range.to_a)
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.cause.is_a?(SQLite3::BusyException)

      puts '[WARN] SQLite database is locked. Please try later.'
    end
  end

  # rake 'player_season_stats:update_price[19,6]'
  desc 'Update player default price after season by tournament id'
  task :update_price, %i[tournament_id season_id] => :environment do |_t, args|
    tournament = Tournament.find_by(id: args[:tournament_id])
    season = Season.find_by(id: args[:season_id])
    next unless tournament || season

    Stats::PriceUpdater.call(tournament, season_id: season.id)
  end
end

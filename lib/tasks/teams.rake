namespace :teams do
  # rake 'teams:reset'
  desc 'Reset teams players'
  task reset: :environment do
    Team.find_each(&:reset)
    puts 'Done!'
  end

  # rake 'teams:reset_league[1]'
  desc 'Reset teams players by league'
  task :reset_league, [:league_id] => :environment do |_t, args|
    league = League.find_by(id: args[:league_id])
    return unless league

    league.teams.each(&:reset)
    puts 'Done!'
  end

  # rake 'teams:reset_tournament[16,6]'
  desc 'Reset teams players by tournament and season'
  task :reset_tournament, %i[tournament_id season_id] => :environment do |_t, args|
    tournament = Tournament.find_by(args[:tournament_id])
    season = Season.find_by(args[:season_id])
    next unless tournament || season

    tournament.leagues.by_season(season).each do |league|
      league.teams.each(&:reset)
    end
    puts 'Done!'
  end
end

namespace :teams do
  desc 'Reset teams players'
  task reset: :environment do
    Team.find_each do |team|
      team.players.clear
      team.update(budget: Team::DEFAULT_BUDGET)
    end
    puts 'Done!'
  end

  desc 'Reset teams players by league'
  task :reset_league, [:league_id] => :environment do |_t, args|
    league = League.find_by(id: args[:league_id])
    return unless league

    league.teams.each do |team|
      team.players.clear
      team.update(budget: Team::DEFAULT_BUDGET)
    end
    puts 'Done!'
  end

  # rake 'teams:reset_tournament[15]'
  desc 'Reset teams players by tournament'
  task :reset_tournament, [:tournament_id] => :environment do |_t, args|
    tournament = Tournament.find_by(id: args[:tournament_id])
    return unless tournament

    tournament.leagues.by_season(Season.last).each do |league|
      league.teams.each do |team|
        team.players.clear
        team.update(budget: Team::DEFAULT_BUDGET)
      end
    end
    puts 'Done!'
  end
end

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
end

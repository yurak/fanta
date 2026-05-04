namespace :teams do
  # rake 'teams:cleanup_orphans'
  # rake 'teams:cleanup_orphans[false]'  # destructive mode
  desc 'Delete teams with no meaningful dependencies (dry-run by default)'
  task :cleanup_orphans, [:dry_run] => :environment do |_t, args|
    Teams::Tasks.cleanup_orphans(dry_run: args[:dry_run] != 'false')
  end

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
    next unless league

    league.teams.each(&:reset)
    puts 'Done!'
  end

  # rake 'teams:reset_tournament[16,6]'
  desc 'Reset teams players by tournament and season'
  task :reset_tournament, %i[tournament_id season_id] => :environment do |_t, args|
    tournament = Tournament.find_by(id: args[:tournament_id])
    season = Season.find_by(id: args[:season_id])
    next unless tournament || season

    tournament.leagues.by_season(season).each do |league|
      league.teams.each(&:reset)
    end
    puts 'Done!'
  end

  # rake 'teams:reset_tournament[15]'
  desc 'Reset teams players by tournament'
  task :reset_tournament, [:tournament_id] => :environment do |_t, args|
    tournament = Tournament.find_by(id: args[:tournament_id])
    next unless tournament

    tournament.leagues.by_season(Season.last).each do |league|
      league.teams.each do |team|
        team.players.clear
        team.update(budget: Team::DEFAULT_BUDGET)
      end
    end
    puts 'Done!'
  end
end

module Teams
  module Tasks
    def self.cleanup_orphans(dry_run:)
      orphans = orphan_teams
      puts "Found #{orphans.count} orphan team(s):"
      orphans.each { |t| puts "  id=#{t.id} name=#{t.human_name} user_id=#{t.user_id}" }

      if dry_run
        puts "\nDry-run mode. Run with [false] to delete."
      else
        orphans.destroy_all
        puts "\nDeleted."
      end
    end

    def self.orphan_teams
      Team
        .where(league_id: nil)
        .where.missing(:join)
        .where.missing(:auction_bids)
        .where.missing(:lineups)
        .where.missing(:results)
        .where.missing(:transfers)
        .where.missing(:player_teams)
        .where('teams.id NOT IN (SELECT host_id FROM matches UNION SELECT guest_id FROM matches)')
    end
  end
end

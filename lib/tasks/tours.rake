namespace :tours do
  desc 'Unlock tour by number'
  task :unlock, [:number] => :environment do |_t, args|
    tour = Tour.find_by(number: args[:number].to_i)
    tour&.set_lineup!
  end

  # rake tours:lock_deadline
  desc 'Lock tours after deadline'
  task lock_deadline: :environment do
    League.active.each do |league|
      league.tours.set_lineup.each do |tour|
        Tours::DeadlineLocker.call(tour)
      end
    end
  end

  # rake 'tours:generate_lineups'
  desc 'Clone missed lineups and generate not-in-squad players for locked tours'
  task generate_lineups: :environment do
    lock_file = Rails.root.join('tmp/generate_lineups.lock')
    File.open(lock_file, File::RDWR | File::CREAT, 0o644) do |f|
      unless f.flock(File::LOCK_EX | File::LOCK_NB)
        puts 'tours:generate_lineups already running, skipping'
        next
      end

      Tour.locked.where(lineups_generated: false).find_each do |tour|
        Tours::LineupGenerator.call(tour)
      end
    end
  end

  # rake 'tours:auto_close'
  desc 'Close moderated tours'
  task auto_close: :environment do
    TournamentRound.moderated.each do |t_round|
      Tours::AutoCloser.call(t_round)
    end
  end

  # rake 'tours:auto_inject'
  desc 'Inject scores for moderated tours'
  task auto_inject: :environment do
    TournamentRound.moderated.each do |t_round|
      Tours::AutoInjector.call(t_round)
    end
  end

  # rake 'tours:live_inject'
  desc 'Inject live scores for in-progress FotMob matches (live_scores_enabled tournaments)'
  task live_inject: :environment do
    # a slow/degraded FotMob can push one run past the 5-min cron interval; the lock stops a
    # second run from re-processing the same rounds concurrently (same overlap guard as generate_lineups)
    lock_file = Rails.root.join('tmp/live_inject.lock')
    File.open(lock_file, File::RDWR | File::CREAT, 0o644) do |f|
      unless f.flock(File::LOCK_EX | File::LOCK_NB)
        puts 'tours:live_inject already running, skipping'
        next
      end

      rounds  = TournamentRound.live_scores_candidates.to_a
      results = rounds.map { |t_round| Tours::LiveInjector.call(t_round) }

      Scores::ScrapeAlert.call(
        candidates: results.sum { |result| result[:candidates] },
        with_data: results.sum { |result| result[:with_data] },
        failures: results.sum { |result| result[:failures] },
        tournaments: rounds.map { |t_round| t_round.tournament.name }.uniq
      )
    end
  end

  # rake 'tours:refresh_schedule'
  desc 'Refresh kickoff times for open rounds (live_scores_enabled FotMob tournaments)'
  task refresh_schedule: :environment do
    TournamentRound.schedule_refresh_candidates.each do |t_round|
      Tours::ScheduleRefresher.call(t_round)
    end
  end

  # rake 'tours:create_national[178]'
  desc 'Create tours for World Cup'
  task :create_national, [:league_id] => :environment do |_t, args|
    tournament = Tournament.find_by(code: 'world_cup')
    league = tournament.leagues.find_by(id: args[:league_id])

    ActiveRecord::Base.transaction do
      tournament.tournament_rounds.by_season(Season.last).each do |round|
        first_match = round.national_matches.first
        deadline = DateTime.parse("#{first_match.date} #{first_match.time}") - 90.minutes
        round.update(deadline: deadline)

        Tour.create(tournament_round: round, league: league, number: round.number)
      end
    end
  end

  # rake tours:create_ecl
  desc 'Create tours for Champions League'
  task create_ecl: :environment do
    tournament = Tournament.find_by(code: Tournament::EUROPE_CL)
    league = tournament.leagues.last
    tournament.tournament_rounds.where(season: Season.last).find_each do |round|
      first_match = round.tournament_matches.first
      next unless first_match

      deadline = DateTime.parse("#{first_match.date} #{first_match.time}") - 90.minutes
      round.update(deadline: deadline)

      Tour.create(tournament_round: round, league: league, number: round.number)
    end
  end
end

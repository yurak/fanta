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

  # rake 'tours:create_national[178]'
  desc 'Create tours for World Cup'
  task :create_national, [:league_id] => :environment do |_t, args|
    tournament = Tournament.find_by(code: Tournament::EURO)
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

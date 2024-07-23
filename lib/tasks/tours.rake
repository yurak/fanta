# rubocop:disable Metrics/BlockLength:
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
        tour_deadline = tour.tournament_round.deadline.asctime.in_time_zone('EET')

        Tours::Manager.call(tour, Tours::Manager::LOCKED_STATUS) if tour_deadline < DateTime.now
      end
    end
  end

  # rake tours:auto_close
  desc 'Close moderated tours'
  task auto_close: :environment do
    TournamentRound.moderated.each do |t_round|
      hours = ((Time.zone.now - t_round.moderated_at) / 3_600).to_i

      if [6, 12, 17].include?(hours)
        Scores::Injectors::Fotmob.call(t_round)
        t_round.tours.each do |tour|
          Scores::PositionMalus::Updater.call(tour)
          Lineups::Updater.call(tour)
        end
      end

      next if hours < TournamentRound::MODERATED_HOURS

      t_round.tours.locked_postponed.each do |tour|
        Tours::Manager.call(tour, Tours::Manager::CLOSED_STATUS)
      end
      t_round.update(moderated_at: nil)
    end
  end

  # rake 'tours:create_national[178]'
  desc 'Create tours for World Cup'
  task :create_national, [:league_id] => :environment do |_t, args|
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::EURO)
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
    tournament = Tournament.find_by(code: Scores::Injectors::Strategy::EUROPE_CL)
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
# rubocop:enable Metrics/BlockLength

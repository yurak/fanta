namespace :substitutes do
  # rake 'substitutes:rollback_round[2653]'        -- dry run, prints what it would undo
  # rake 'substitutes:rollback_round[2653,apply]'  -- actually undoes them
  desc 'Undo every substitution made in a tournament round'
  task :rollback_round, %i[round_id mode] => :environment do |_t, args|
    round = TournamentRound.find(args[:round_id])
    apply = args[:mode].to_s == 'apply'
    subs = Substitute.joins(main_mp: { lineup: :tour }).where(tours: { tournament_round_id: round.id })
    lineups = Lineup.joins(:tour).where(tours: { tournament_round_id: round.id }).where.not(substitutes: nil)

    puts "round #{round.id} (#{round.tournament.code} #{round.number}): #{subs.count} substitutions, " \
         "#{lineups.count} stored previews"
    next puts('Dry run. Pass `apply` as the second argument to undo them.') unless apply

    undone = subs.pluck(:id).count { |id| Substitutes::Destroyer.call(id) }
    cleared = lineups.update_all(substitutes: nil) # rubocop:disable Rails/SkipsModelValidations

    puts "Undone: #{undone}, previews cleared: #{cleared}, left behind: #{subs.reload.count}"
  end
end

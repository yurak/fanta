namespace :signups do
  # rake 'signups:purge_unconfirmed'           -- dry run, 30 days
  # rake 'signups:purge_unconfirmed[60]'       -- dry run, a different age
  # rake 'signups:purge_unconfirmed[30,apply]' -- actually removes them
  desc 'Remove old unconfirmed sign-ups that never created anything'
  task :purge_unconfirmed, %i[days mode] => :environment do |_t, args|
    purge = Signups::StalePurge.new(days: args[:days] || Signups::StalePurge::DEFAULT_DAYS)

    puts "unconfirmed older than #{purge.days} days: #{purge.removable.size + purge.kept.size}"
    puts "  carry nothing, removable: #{purge.removable.size}"
    puts "  have something, kept:     #{purge.kept.size}"
    purge.kept.first(20).each { |user| puts "    #{user.id}  #{user.email}  created #{user.created_at.to_date}" }
    puts "    ... and #{purge.kept.size - 20} more" if purge.kept.size > 20
    puts "newer than #{purge.days} days, left alone: #{purge.newer_count}"

    next puts("\nDry run. Pass `apply` as the second argument to remove them.") unless args[:mode].to_s == 'apply'

    puts "\nRemoved: #{purge.purge!}. Unconfirmed left: #{User.where(confirmed_at: nil).count}"
  end
end

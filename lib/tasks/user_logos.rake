namespace :user_logos do
  # rake user_logos:backfill
  desc 'Add custom logos currently attached to teams into their owners user_logos collections (approved)'
  task backfill: :environment do
    default_icons_prefix = "#{S3Storage.bucket_url}/teams/default_icons/"

    created = 0
    skipped = 0

    teams = Team.where.not(logo_url: [nil, ''])
                .where.not(user_id: nil)
                .where.not('logo_url LIKE ?', "#{default_icons_prefix}%")

    teams.find_each do |team|
      logo = UserLogo.find_or_initialize_by(user_id: team.user_id, url: team.logo_url)

      if logo.persisted?
        skipped += 1
        next
      end

      logo.update!(status: :approved)
      created += 1
      puts "Added logo for user #{team.user_id}: #{team.logo_url}"
    end

    puts "Done. Created: #{created}, skipped (already present): #{skipped}"
  end
end

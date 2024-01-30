namespace :tg do
  # rake 'tg:send_tour_deadline'
  desc 'Send notifications to Telegram about tour deadline'
  task send_tour_deadline: :environment do
    League.active.each do |league|
      league.tours.set_lineup.each do |tour|
        next unless tour.tournament_round.deadline

        tour_deadline = tour.tournament_round.deadline.asctime.in_time_zone('EET')

        next if DateTime.now < (tour_deadline - 3.hours)

        tour.teams.each do |team|
          user = team.user
          next unless user.user_profile&.bot_enabled
          next if team.lineups&.find_by(tour: tour)

          message = "#{league.tournament.icon} The deadline is coming soon - today at #{tour_deadline&.strftime('%H:%M')} (EET) 🔚\n" \
                    "🟡 Create your lineup #{Rails.application.routes.url_helpers.tour_url(tour)}"

          TelegramBot::Sender.call(user, message)
        end
      end
    end
  end
end

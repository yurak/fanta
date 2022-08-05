namespace :tg do
  desc 'Send notifications to Telegram'
  task send_notifications: :environment do
    League.active.each do |league|
      league.tours.set_lineup.each do |tour|
        next unless tour.tournament_round.deadline

        tour_deadline = tour.tournament_round.deadline.asctime.in_time_zone('EET')

        next if DateTime.now < (tour_deadline - 2.hours)

        tour.teams.each do |team|
          user = team.user
          next unless user.user_profile&.bot_enabled
          next if team.lineups&.find_by(tour: tour)

          TelegramBot::Sender.call(user,
                                   "The deadline is coming soon! Create your lineup #{Rails.application.routes.url_helpers.tour_url(tour)}")
        end
      end
    end
  end
end

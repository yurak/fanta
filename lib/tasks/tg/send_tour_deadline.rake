namespace :tg do
  # rake 'tg:send_tour_deadline'
  desc 'Send notifications to Telegram about tour deadline'
  task send_tour_deadline: :environment do
    League.active.each do |league|
      league.tours.set_lineup.each do |tour|
        next unless tour.tournament_round.deadline
        next if DateTime.now < (tour.tournament_round.deadline - 3.hours)

        TelegramBot::Tour::DdlNotifier.call(tour)
      end
    end
  end
end

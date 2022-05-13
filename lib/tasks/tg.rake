namespace :tg do
  desc 'Unlock tour by number'
  task send_notification: :environment do
    League.active.each do |league|
      league.tours.set_lineup.each do |tour|
        next unless tour.tournament_round.deadline

        tour_deadline = tour.tournament_round.deadline.asctime.in_time_zone('EET')

        next if DateTime.now < (tour_deadline - 2.hours) && tour_deadline.today?

        tour.teams.each do |team|
          user = team.user
          next unless user.user_profile&.bot_enabled

          p team.user
          Telegram.bots[:mantra_prod].send_message(chat_id: user.user_profile.tg_chat_id,
                                                   text: "#{user.name} please setup lineup for tour: #{tour.tournament_round.number}")
        end
      end
    end
  end
end

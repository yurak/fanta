# rubocop:disable Metrics/BlockLength:
namespace :tg do
  # rake 'tg:send_notifications'
  desc 'Send notifications to Telegram'
  task send_notifications: :environment do
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

  # rake 'tg:save_messages'
  desc 'Save messages from Telegram Bot'
  task save_messages: :environment do
    updates = Telegram.bot.get_updates['result']
    next if updates&.empty?

    updates.each do |tg_update|
      tg_message = TgMessage.find_by(update_id: tg_update['update_id'])
      next if tg_message

      message = TgMessage.new(update_id: tg_update['update_id'], full_data: tg_update)
      if tg_update['message']
        message.assign_attributes(
          message_id: tg_update['message']['message_id'],
          chat_id: tg_update['message']['chat']['id'],
          text: tg_update['message']['text'],
          username: tg_update['message']['from']['username'],
          first_name: tg_update['message']['from']['first_name'],
          last_name: tg_update['message']['from']['last_name'],
          date: Time.zone.at(tg_update['message']['date']).to_datetime
        )
      end
      message.save
    end
  end
end
# rubocop:enable Metrics/BlockLength

namespace :notifications do
  # rake 'notifications:send_pending'
  desc 'Send pending notifications in batches'
  task send_pending: :environment do
    Notifications::SendPendingJob.perform_now
  end

  # rake 'notifications:trial_leagues'
  desc 'Send trial leagues recruitment notification to users without any joins'
  task trial_leagues: :environment do
    icons = Tournament.where(id: [1, 2, 3, 4, 5]).order(:id).map(&:icon).join(' ')

    users = User.where.missing(:joins).includes(:user_profile)

    sent = 0
    skipped = 0

    users.find_each do |user|
      unless user.user_profile&.bot_enabled
        skipped += 1
        next
      end

      message = "Вітаю!\nТриває набір на пробні ліги у чемпіонатах #{icons}\n\n" \
                "Участь в пробних лігах безкоштовна 🆓\n\n" \
                "Заявки уже можна створювати  на сайті, щоб спробувати себе в нових чемпіонатах ➕\n\n" \
                "Також запрошуйте ваших друзів - разом грати веселіше 🍻\n\n" \
                'Якщо у вас є будь-які питання - пишіть @mantra_help'

      TelegramBot::Sender.call(user, message)
      sent += 1
    end

    puts "Done. Sent: #{sent}, skipped (no Telegram): #{skipped}"
  end
end

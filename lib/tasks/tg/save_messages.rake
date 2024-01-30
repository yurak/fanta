namespace :tg do
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

module Telegram
  class WebhookController < Telegram::Bot::UpdatesController

    include Telegram::Bot::UpdatesController::MessageContext
    include Rails.application.routes.url_helpers

    # Telegram::Bot::UpdatesPoller.start(Telegram.bot, Telegram::WebhookController)

    def start!(*)
      save_message
      reply_with :photo, photo: File.open('app/assets/images/mantra_logo.jpeg')
      respond_with :message, text: t('telegram_webhooks.start.text', locale: locale), reply_markup: {
        inline_keyboard: [
          [
            { text: t('telegram_webhooks.start.register', locale: locale), callback_data: 'register' },
            { text: t('telegram_webhooks.start.learn_more', locale: locale), callback_data: 'learn_more' },
          ],
        ],
        resize_keyboard: true,
        one_time_keyboard: true,
        selective: true,
      }
    end

    def help!(*)
      respond_with :message, text: t('telegram_webhooks.help.content', locale: locale)
    end

    def register!(*)
      save_context :check_email
      respond_with :message, text: t('telegram_webhooks.register.text', locale: locale)
    end

    def learn_more!(*)
      respond_with :message, text: t('telegram_webhooks.learn_more.text', locale: locale), reply_markup: {
        inline_keyboard: [
          [{text: t('telegram_webhooks.learn_more.rules', locale: locale), url: rules_url(host: host) }],
        ],
      }
      reply_with :document, document: File.open('public/rules_short_ua.pdf')
      reply_with :document, document: File.open('public/rules_extended_ua.pdf')
      reply_with :document, document: File.open('public/rules_en.pdf')
    end

    def callback_query(data)
      if data == 'register'
        register!
      end
      if data == 'learn_more'
        learn_more!
      end
    end

    def check_email(*words)
      save_message

      email = words[0].html_safe
      user = User.find_by(email: email)
      profile = UserProfile.find_by(tg_chat_id: from['id'])

      if user
        respond_with :message, text: t('telegram_webhooks.register.email_exist', locale: locale)
      elsif profile
        respond_with :message, text: t('telegram_webhooks.register.chat_exist', locale: locale)
      else
        respond_with :message, text: t('telegram_webhooks.register.success', locale: locale), reply_markup: {
          inline_keyboard: [
            [{text: t('telegram_webhooks.register.sign_up', locale: locale), url: new_user_registration_url(email: email, host: host) }],
          ],
        }
      end
    end

    def contacts!(*)
      respond_with :message, text: t('telegram_webhooks.contacts.text', locale: locale)
    end

    def action_missing(action, *_args)
      if action_type == :command
        save_message

        respond_with :message,
                     text: t('telegram_webhooks.action_missing.command', command: action_options[:command], locale: locale)
      end
    end

    private

    def save_message
      return unless update && payload

      TgMessage.create(
        update_id: update['update_id'],
        full_data: update,
        message_id: payload['message_id'],
        chat_id: payload['chat']['id'],
        text: payload['text'],
        username: payload['from']['username'],
        first_name: payload['from']['first_name'],
        last_name: payload['from']['last_name'],
        date: Time.zone.at(payload['date']).to_datetime
      )
    end

    def locale
      I18n.available_locales.include?(from['language_code'].to_sym) ? from['language_code'].to_sym : :en
    end

    def host
      Rails.application.config.telegram_updates_controller.host
    end
  end
end

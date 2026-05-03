module Telegram
  class WebhookController < Telegram::Bot::UpdatesController
    include Telegram::Bot::UpdatesController::MessageContext
    include Rails.application.routes.url_helpers

    def start!(*args)
      token = args[0]

      if token.present?
        connect_by_token(token)
        return
      end

      save_message
      send_start_message
    rescue Telegram::Bot::Forbidden => e
      Rails.logger.warn("Telegram error for chat #{payload['chat']['id']}: #{e.message}")
    end

    def help!(*)
      respond_with :message, text: t('telegram.webhooks.help.content', locale: locale)
    end

    def register!(*)
      save_context :check_email
      respond_with :message, text: t('telegram.webhooks.register.text', locale: locale)
    end

    def learn_more!(*)
      respond_with :message, text: t('telegram.webhooks.learn_more.text', locale: locale), reply_markup: {
        inline_keyboard: [
          [{ text: t('telegram.webhooks.learn_more.rules', locale: locale), url: rules_url(host: host, locale: locale) }],
          [{ text: t('telegram.webhooks.learn_more.podcast', locale: locale), url: 'https://youtu.be/P4yh8PXipa4?si=FMme8cul9JJ2bKrC' }]
        ]
      }
      %w[rules_short_ua.pdf rules_extended_ua.pdf rules_en.pdf].each do |filename|
        File.open("public/#{filename}") { |f| reply_with :document, document: f }
      end
    end

    def callback_query(data)
      case data
      when 'register'   then register!
      when 'learn_more' then learn_more!
      end
    end

    def check_email(*words)
      save_message

      return if words[0].blank?

      email = words[0].downcase
      user = User.find_by(email: email)

      if user
        email_exist_response
      elsif profile
        respond_with :message, text: t('telegram.webhooks.register.chat_exist', locale: locale)
      else
        email_valid_response(email)
      end
    end

    def contacts!(*)
      respond_with :message, text: t('telegram.webhooks.contacts.text', locale: locale)
    end

    def action_missing(_action, *_args)
      return unless action_type == :command

      save_message

      respond_with :message,
                   text: t('telegram.webhooks.action_missing.command', command: action_options[:command], locale: locale)
    end

    private

    def send_start_message
      respond_with :message, text: t('telegram.webhooks.start.text', locale: locale), reply_markup: {
        inline_keyboard: [
          [
            { text: t('telegram.webhooks.start.register', locale: locale), callback_data: 'register' },
            { text: t('telegram.webhooks.start.learn_more', locale: locale), callback_data: 'learn_more' }
          ]
        ],
        resize_keyboard: true,
        one_time_keyboard: true,
        selective: true
      }
    end

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
        date: Time.zone.at(payload['date'] || Time.current.to_i).to_datetime
      )
    end

    def email_exist_response
      respond_with :message, text: t('telegram.webhooks.register.email_exist', locale: locale), reply_markup: {
        inline_keyboard: [
          [{ text: t('telegram.webhooks.start.register', locale: locale), callback_data: 'register' }]
        ]
      }
    end

    def email_valid_response(email)
      token = SecureRandom.hex(16)
      Rails.cache.write("tg_connect:#{token}", from['id'], expires_in: 1.hour)

      respond_with :message, text: t('telegram.webhooks.register.success', locale: locale), reply_markup: {
        inline_keyboard: [
          [{ text: t('telegram.webhooks.register.sign_up', locale: locale),
             url: new_user_registration_url(email: email, tg_token: token, host: host, locale: locale) }]
        ]
      }
    end

    def connect_by_token(token)
      profile = UserProfile.find_by(tg_connect_token: token)
      if linkable?(profile)
        profile.update(tg_chat_id: from['id'], bot_enabled: true, tg_connect_token: nil, tg_connect_expires_at: nil)
        respond_with :message, text: t('telegram.webhooks.start.connected', locale: locale)
      else
        respond_with :message, text: t('telegram.webhooks.start.connect_failed', locale: locale)
      end
    end

    def linkable?(profile)
      profile.present? && profile.tg_connect_expires_at.present? && profile.tg_connect_expires_at >= Time.current
    end

    def profile
      UserProfile.find_by(tg_chat_id: from['id'])
    end

    def locale
      return :ua if from['language_code'] == 'uk'

      :en
    end

    def host
      Rails.application.config.telegram_updates_controller.host
    end
  end
end

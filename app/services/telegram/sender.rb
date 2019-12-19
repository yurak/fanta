require 'telegram/bot'

module Telegram
  class Sender < ApplicationService
    attr_reader :text

    TELEGRAM_CHAT_ID = ENV['TELEGRAM_CHAT_ID']
    TELEGRAM_BOT_TOKEN = ENV['TELEGRAM_BOT_TOKEN']

    def initialize(text:)
      @text = text
    end

    def call
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: text, parse_mode: 'html')
    rescue Telegram::Bot::Exceptions::ResponseError => e
      Rails.logger.error("Telegram bot return exception: #{e}")
    end

    private

    def bot
      @bot ||= Telegram::Bot::Client.new(TELEGRAM_BOT_TOKEN)
    end
  end
end

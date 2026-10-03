# frozen_string_literal: true

module TelegramBot
  module Recipient
    private

    def locale
      user&.locale&.to_sym || :en
    end

    def time_zone
      user&.time_zone.presence || User::DEFAULT_TIME_ZONE
    end
  end
end

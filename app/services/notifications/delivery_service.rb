module Notifications
  class DeliveryService < ApplicationService
    attr_reader :notification

    def initialize(notification)
      @notification = notification
    end

    def call
      case notification.kind.to_sym
      when :tour_opened
        deliver_tour_opened
      when :tour_moderated
        deliver_tour_moderated
      when :tour_closed
        deliver_tour_closed
      else
        raise "Unknown notification kind: #{notification.kind}"
      end
    end

    private

    def deliver_tour_opened
      TelegramBot::Tour::OpenedNotifier.call(notification)
    end

    def deliver_tour_moderated
      TelegramBot::Tour::ModeratedNotifier.call(notification)
    end

    def deliver_tour_closed
      TelegramBot::Tour::ClosedNotifier.call(notification)
    end
  end
end

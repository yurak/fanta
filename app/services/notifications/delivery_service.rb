module Notifications
  class DeliveryService < ApplicationService
    NOTIFIER_MAP = {
      tour_opened: TelegramBot::Tour::OpenedNotifier,
      tour_moderated: TelegramBot::Tour::ModeratedNotifier,
      tour_closed: TelegramBot::Tour::ClosedNotifier,
      auction_sales_open: TelegramBot::Auction::SalesOpenNotifier,
      auction_closed: TelegramBot::Auction::ClosedNotifier,
      auction_sales_ddl: TelegramBot::Auction::SalesDdlNotifier,
      auction_start_bids: TelegramBot::Auction::StartBidsNotifier,
      auction_round_ddl: TelegramBot::Auction::RoundDdlNotifier,
      auction_squad_complete: TelegramBot::Auction::SquadCompleteNotifier
    }.freeze

    attr_reader :notification

    def initialize(notification)
      @notification = notification
    end

    def call
      notifier = NOTIFIER_MAP[notification.kind.to_sym]
      raise "Unknown notification kind: #{notification.kind}" unless notifier

      notifier.call(notification)
    end
  end
end

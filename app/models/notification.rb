class Notification < ApplicationRecord
  belongs_to :team
  belongs_to :notifiable, polymorphic: true

  PENDING = 'pending'.freeze

  enum :status, {
    pending: 0,
    sent: 1,
    failed: 2,
    processing: 3
  }

  enum :kind, {
    tour_opened: 0,
    tour_ddl: 1,
    tour_moderated: 2,
    tour_closed: 3,
    auction_sales_open: 4,
    auction_closed: 5,
    auction_sales_ddl: 6,
    auction_start_bids: 7,
    auction_round_ddl: 8,
    auction_squad_complete: 9
  }

  enum :priority, {
    low: 0,
    normal: 1,
    high: 2,
    critical: 3
  }
end

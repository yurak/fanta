class Notification < ApplicationRecord
  belongs_to :team
  belongs_to :notifiable, polymorphic: true

  PENDING = 'pending'.freeze

  enum status: {
    pending: 0,
    sent: 1,
    failed: 2
  }

  enum kind: {
    tour_opened: 0,
    tour_ddl: 1,
    tour_moderated: 2,
    tour_closed: 3
  }

  enum priority: {
    low: 0,
    normal: 1,
    high: 2,
    critical: 3
  }
end

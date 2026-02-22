module Notifications
  class SendPendingJob < ApplicationJob
    queue_as :default

    BATCH_SIZE = 30

    def perform
      Notification.pending.order(priority: :desc, id: :asc).limit(BATCH_SIZE).each do |notification|
        Notifications::DeliveryService.call(notification)
        notification.update!(status: :sent, sent_at: Time.current)
      rescue => e
        notification.update!(status: :failed, error_message: e.message)
      end
    end
  end
end

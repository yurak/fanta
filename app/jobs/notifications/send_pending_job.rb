module Notifications
  class SendPendingJob < ApplicationJob
    queue_as :default

    BATCH_SIZE = 30

    def perform
      ids = Notification.pending.order(priority: :desc, id: :asc).limit(BATCH_SIZE).ids
      return if ids.empty?

      Notification.where(id: ids, status: :pending).update_all(status: :processing) # rubocop:disable Rails/SkipsModelValidations
      Notification.processing.where(id: ids).order(priority: :desc, id: :asc).each do |notification|
        Notifications::DeliveryService.call(notification)
        notification.update!(status: :sent, sent_at: Time.current)
      rescue => e
        notification.update!(status: :failed, error_message: e.message)
      end
    end
  end
end

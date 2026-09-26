module Notifications
  class SendPendingJob < ApplicationJob
    queue_as :default

    BATCH_SIZE = 30
    # The requeue threshold has to clear the slowest batch a worker can legitimately run: the
    # Telegram client waits up to 60s per message, so 30 of them can take half an hour. Anything
    # shorter and a live batch would be handed to a second worker — the same message twice.
    STUCK_AFTER = 45.minutes
    # Must stay above STUCK_AFTER: a row is only requeued while it is both abandoned and still
    # current, so the two thresholds together define that window.
    TOO_LATE_AFTER = 2.hours
    MAX_ATTEMPTS = 3

    def perform
      requeue_recoverable
      retire_stale

      ids = claim_batch
      return if ids.empty?

      deliver(ids)
    end

    private

    def requeue_recoverable
      recoverable.where(attempts: ...MAX_ATTEMPTS)
                 .update_all(status: :pending, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end

    def recoverable
      Notification.where(status: %i[processing failed])
                  .where(created_at: TOO_LATE_AFTER.ago..)
                  .where(updated_at: ...STUCK_AFTER.ago)
    end

    def retire_stale
      Notification.processing
                  .where(created_at: ...TOO_LATE_AFTER.ago)
                  .where(updated_at: ...STUCK_AFTER.ago)
                  .update_all(status: :failed, error_message: 'stale, never delivered', # rubocop:disable Rails/SkipsModelValidations
                              updated_at: Time.current)
    end

    def claim_batch
      ids = Notification.pending.where(attempts: ...MAX_ATTEMPTS)
                        .order(priority: :desc, id: :asc).limit(BATCH_SIZE).ids
      return ids if ids.empty?

      Notification.where(id: ids, status: :pending)
                  .update_all(status: :processing, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      ids
    end

    def deliver(ids)
      Notification.processing.where(id: ids).order(priority: :desc, id: :asc).each do |notification|
        notification.increment!(:attempts) # rubocop:disable Rails/SkipsModelValidations
        Notifications::DeliveryService.call(notification)
        notification.update!(status: :sent, sent_at: Time.current)
      rescue StandardError => e
        notification.update!(status: :failed, error_message: e.message)
      end
    end
  end
end

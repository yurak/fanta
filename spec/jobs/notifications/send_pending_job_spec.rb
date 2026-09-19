# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::SendPendingJob do
  subject(:perform) { described_class.perform_now }

  before { allow(Notifications::DeliveryService).to receive(:call) }

  describe '#perform' do
    context 'when there are no pending notifications' do
      it 'does not call DeliveryService' do
        perform

        expect(Notifications::DeliveryService).not_to have_received(:call)
      end
    end

    context 'when there is a pending notification' do
      let!(:notification) { create(:notification, status: :pending) }

      it 'calls DeliveryService with the notification' do
        perform

        expect(Notifications::DeliveryService).to have_received(:call).with(notification).once
      end

      it 'transitions to processing state before delivery' do
        allow(Notifications::DeliveryService).to receive(:call) do
          expect(notification.reload).to be_processing
        end
        perform
      end

      it 'marks the notification as sent after delivery' do
        perform

        expect(notification.reload).to be_sent
      end

      it 'sets sent_at' do
        perform

        expect(notification.reload.sent_at).to be_present
      end
    end

    context 'when DeliveryService raises an error' do
      let!(:notification) { create(:notification, status: :pending) }

      before { allow(Notifications::DeliveryService).to receive(:call).and_raise('Telegram error') }

      it 'marks the notification as failed' do
        perform

        expect(notification.reload).to be_failed
      end

      it 'stores the error message' do
        perform

        expect(notification.reload.error_message).to eq('Telegram error')
      end

      it 'does not re-raise the error' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when a notification is already in processing state (concurrent job scenario)' do
      let!(:processing_notification) { create(:notification, status: :processing) }

      it 'does not deliver the already-processing notification' do
        perform

        expect(Notifications::DeliveryService).not_to have_received(:call)
      end

      it 'leaves the notification in processing state' do
        perform

        expect(processing_notification.reload).to be_processing
      end
    end

    context 'when pending and processing notifications coexist' do
      let!(:pending_notification) { create(:notification, status: :pending) }
      let!(:processing_notification) { create(:notification, status: :processing) }

      it 'delivers the pending notification' do
        perform

        expect(Notifications::DeliveryService).to have_received(:call)
          .with(pending_notification).once
      end

      it 'does not deliver the already-processing notification' do
        perform

        expect(Notifications::DeliveryService).not_to have_received(:call)
          .with(processing_notification)
      end
    end

    context 'when there are more than BATCH_SIZE pending notifications' do
      let(:batch_size) { described_class::BATCH_SIZE }
      let(:team) { create(:team) }
      let(:tour) { create(:tour) }

      before do
        (batch_size + 5).times { create(:notification, status: :pending, team: create(:team), notifiable: tour) }
      end

      it 'processes only BATCH_SIZE notifications' do
        perform

        expect(Notifications::DeliveryService).to have_received(:call).exactly(batch_size).times
      end

      it 'leaves the remaining notifications as pending' do
        perform

        expect(Notification.pending.count).to eq(5)
      end
    end

    context 'when notifications have different priorities' do
      let!(:low)    { create(:notification, status: :pending, priority: :low) }
      let!(:high)   { create(:notification, status: :pending, priority: :high) }
      let!(:normal) { create(:notification, status: :pending, priority: :normal) }

      it 'delivers higher-priority notifications first' do
        call_order = []
        allow(Notifications::DeliveryService).to receive(:call) { |n| call_order << n.id }

        perform

        expect(call_order).to eq([high.id, normal.id, low.id])
      end
    end

    # A process that dies mid-batch used to leave its rows in `processing` for good: 51 of them sat
    # there from the spring, and nobody ever received those.
    context 'when a batch was abandoned by a dead process' do
      let!(:abandoned) do
        create(:notification, status: :processing, created_at: 1.hour.ago, updated_at: 50.minutes.ago)
      end

      it 'delivers it on the next run' do
        perform

        expect(Notifications::DeliveryService).to have_received(:call).with(abandoned)
      end
    end

    context 'when a claimed row is still being worked on' do
      let!(:in_flight) do
        create(:notification, status: :processing, created_at: 1.hour.ago, updated_at: 1.minute.ago)
      end

      # Taking it back now would hand the same message to two workers.
      it 'leaves it alone' do
        perform

        expect(Notifications::DeliveryService).not_to have_received(:call).with(in_flight)
      end
    end

    context 'when an abandoned row is older than the event it announces' do
      let!(:stale) do
        create(:notification, status: :processing, created_at: 4.hours.ago, updated_at: 4.hours.ago)
      end

      it 'does not deliver it' do
        perform

        expect(Notifications::DeliveryService).not_to have_received(:call).with(stale)
      end

      it 'retires it' do
        perform

        expect(stale.reload).to be_failed
      end

      it 'says why' do
        perform

        expect(stale.reload.error_message).to eq('stale, never delivered')
      end
    end

    context 'when a delivery failed on a timeout' do
      let!(:failed) do
        create(:notification, status: :failed, attempts: 1, error_message: 'execution expired',
                              created_at: 1.hour.ago, updated_at: 50.minutes.ago)
      end

      it 'tries again' do
        perform

        expect(Notifications::DeliveryService).to have_received(:call).with(failed)
      end
    end

    context 'when a delivery keeps failing' do
      let!(:exhausted) do
        create(:notification, status: :failed, attempts: described_class::MAX_ATTEMPTS,
                              created_at: 1.hour.ago, updated_at: 50.minutes.ago)
      end

      # Without the cap it would come back every minute and eat a slot of every batch.
      it 'gives up on it' do
        perform

        expect(Notifications::DeliveryService).not_to have_received(:call).with(exhausted)
      end
    end

    it 'counts the attempt even when the delivery blows up' do
      notification = create(:notification, status: :pending)
      allow(Notifications::DeliveryService).to receive(:call).and_raise(StandardError, 'boom')

      perform

      expect(notification.reload.attempts).to eq(1)
    end
  end
end

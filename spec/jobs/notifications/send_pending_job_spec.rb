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

      before { create_list(:notification, batch_size + 5, status: :pending, team: team, notifiable: tour) }

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
  end
end

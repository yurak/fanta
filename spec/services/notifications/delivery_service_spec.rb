# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::DeliveryService do
  subject(:service_call) { described_class.call(notification) }

  let(:notification) { instance_double(Notification, kind: kind) }

  before do
    allow(TelegramBot::Tour::OpenedNotifier).to receive(:call)
    allow(TelegramBot::Tour::ModeratedNotifier).to receive(:call)
    allow(TelegramBot::Tour::ClosedNotifier).to receive(:call)
  end

  describe '#call' do
    context 'when kind is tour_opened' do
      let(:kind) { :tour_opened }

      it 'calls TelegramBot::Tour::OpenedNotifier with notification' do
        service_call

        expect(TelegramBot::Tour::OpenedNotifier).to have_received(:call).with(notification).once
      end
    end

    context 'when kind is tour_moderated' do
      let(:kind) { :tour_moderated }

      it 'calls TelegramBot::Tour::ModeratedNotifier with notification' do
        service_call

        expect(TelegramBot::Tour::ModeratedNotifier).to have_received(:call).with(notification).once
      end
    end

    context 'when kind is tour_closed' do
      let(:kind) { :tour_closed }

      it 'calls TelegramBot::Tour::ClosedNotifier with notification' do
        service_call

        expect(TelegramBot::Tour::ClosedNotifier).to have_received(:call).with(notification).once
      end
    end

    context 'when kind is unknown' do
      let(:kind) { :unknown_kind }

      it 'raises an error' do
        expect { service_call }.to raise_error(RuntimeError, /Unknown notification kind/)
      end
    end

    context 'when notification.kind is a string' do
      let(:kind) { 'tour_opened' }

      it 'still routes correctly' do
        service_call
        expect(TelegramBot::Tour::OpenedNotifier).to have_received(:call).with(notification).once
      end
    end
  end
end

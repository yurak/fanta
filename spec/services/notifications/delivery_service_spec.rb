# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::DeliveryService do
  subject(:service_call) { described_class.call(notification) }

  let(:notification) { instance_double(Notification, kind: kind) }

  before do
    allow(TelegramBot::Tour::OpenedNotifier).to receive(:call)
    allow(TelegramBot::Tour::ModeratedNotifier).to receive(:call)
    allow(TelegramBot::Tour::ClosedNotifier).to receive(:call)
    allow(TelegramBot::Auction::SalesOpenNotifier).to receive(:call)
    allow(TelegramBot::Auction::ClosedNotifier).to receive(:call)
    allow(TelegramBot::Auction::SalesDdlNotifier).to receive(:call)
    allow(TelegramBot::Auction::StartBidsNotifier).to receive(:call)
    allow(TelegramBot::Auction::RoundDdlNotifier).to receive(:call)
    allow(TelegramBot::Auction::SquadCompleteNotifier).to receive(:call)
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

    context 'when kind is auction_sales_open' do
      let(:kind) { :auction_sales_open }

      it 'calls TelegramBot::Auction::SalesOpenNotifier with notification' do
        service_call

        expect(TelegramBot::Auction::SalesOpenNotifier).to have_received(:call).with(notification).once
      end
    end

    context 'when kind is auction_closed' do
      let(:kind) { :auction_closed }

      it 'calls TelegramBot::Auction::ClosedNotifier with notification' do
        service_call

        expect(TelegramBot::Auction::ClosedNotifier).to have_received(:call).with(notification).once
      end
    end

    context 'when kind is auction_sales_ddl' do
      let(:kind) { :auction_sales_ddl }

      it 'calls TelegramBot::Auction::SalesDdlNotifier with notification' do
        service_call

        expect(TelegramBot::Auction::SalesDdlNotifier).to have_received(:call).with(notification).once
      end
    end

    context 'when kind is auction_start_bids' do
      let(:kind) { :auction_start_bids }

      it 'calls TelegramBot::Auction::StartBidsNotifier with notification' do
        service_call

        expect(TelegramBot::Auction::StartBidsNotifier).to have_received(:call).with(notification).once
      end
    end

    context 'when kind is auction_round_ddl' do
      let(:kind) { :auction_round_ddl }

      it 'calls TelegramBot::Auction::RoundDdlNotifier with notification' do
        service_call

        expect(TelegramBot::Auction::RoundDdlNotifier).to have_received(:call).with(notification).once
      end
    end

    context 'when kind is auction_squad_complete' do
      let(:kind) { :auction_squad_complete }

      it 'calls TelegramBot::Auction::SquadCompleteNotifier with notification' do
        service_call

        expect(TelegramBot::Auction::SquadCompleteNotifier).to have_received(:call).with(notification).once
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

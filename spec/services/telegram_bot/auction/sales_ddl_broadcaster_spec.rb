# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramBot::Auction::SalesDdlBroadcaster do
  subject(:broadcaster) { described_class.new }

  let(:league) { create(:active_league) }

  before { allow(Notifications::Creator).to receive(:call) }

  context 'when league has no sales auction' do
    it 'does not call Notifications::Creator' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when sales auction has no deadline' do
    before { create(:auction, league: league, status: :sales, deadline: nil) }

    it 'does not call Notifications::Creator' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when deadline is more than 18 hours away' do
    before { create(:auction, league: league, status: :sales, deadline: 20.hours.from_now) }

    it 'does not call Notifications::Creator' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when deadline is within 18 hours' do
    let(:auction) { create(:auction, league: league, status: :sales, deadline: 10.hours.from_now) }

    before { auction }

    it 'calls Notifications::Creator with the auction' do
      broadcaster.call
      expect(Notifications::Creator).to have_received(:call).with(notifiable: auction, kind: :auction_sales_ddl)
    end
  end

  context 'when league is not active' do
    let(:inactive_league) { create(:league) }

    before { create(:auction, league: inactive_league, status: :sales, deadline: 10.hours.from_now) }

    it 'does not call Notifications::Creator' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end
end

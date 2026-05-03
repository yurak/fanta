# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramBot::Auction::RoundDdlBroadcaster do
  subject(:broadcaster) { described_class.new }

  let(:league)  { create(:active_league) }
  let(:auction) { create(:auction, league: league) }

  before { allow(Notifications::Creator).to receive(:call) }

  context 'when auction round has no deadline' do
    before { create(:auction_round, auction: auction, deadline: nil) }

    it 'does not call Notifications::Creator' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when deadline is more than 3 hours away' do
    before { create(:auction_round, auction: auction, deadline: 4.hours.from_now) }

    it 'does not call Notifications::Creator' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when deadline is less than 2.5 hours away' do
    before { create(:auction_round, auction: auction, deadline: 2.hours.from_now) }

    it 'does not call Notifications::Creator' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when deadline is within the 3h–2.5h window' do
    let(:round) { create(:auction_round, auction: auction, deadline: 2.75.hours.from_now) }

    before { round }

    it 'calls Notifications::Creator with the round' do
      broadcaster.call
      expect(Notifications::Creator).to have_received(:call).with(notifiable: round, kind: :auction_round_ddl)
    end
  end

  context 'when auction league is not active' do
    let(:inactive_league)  { create(:league) }
    let(:inactive_auction) { create(:auction, league: inactive_league) }

    before { create(:auction_round, auction: inactive_auction, deadline: 2.75.hours.from_now) }

    it 'does not call Notifications::Creator' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end

  context 'when auction round is closed (not active)' do
    before { create(:closed_auction_round, auction: auction, deadline: 2.75.hours.from_now) }

    it 'does not call Notifications::Creator' do
      broadcaster.call
      expect(Notifications::Creator).not_to have_received(:call)
    end
  end
end

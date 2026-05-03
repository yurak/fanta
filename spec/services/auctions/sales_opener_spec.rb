# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Auctions::SalesOpener do
  subject(:opener) { described_class.new(auction) }

  let(:league)  { create(:active_league) }
  let(:auction) { create(:auction, league: league, number: 2, deadline: 100.hours.from_now) }

  before { allow(Auctions::Manager).to receive(:call) }

  context 'when auction has no deadline' do
    let(:auction) { create(:auction, league: league, number: 2, deadline: nil) }

    it { expect(opener.call).to be(false) }

    it 'does not call Auctions::Manager' do
      opener.call
      expect(Auctions::Manager).not_to have_received(:call)
    end
  end

  context 'when auction is primary (number 1)' do
    let(:auction) { create(:auction, league: league, number: 1, deadline: 100.hours.from_now) }

    it { expect(opener.call).to be(false) }

    it 'does not call Auctions::Manager' do
      opener.call
      expect(Auctions::Manager).not_to have_received(:call)
    end
  end

  context 'when deadline is more than HOURS_FOR_SALES away' do
    let(:auction) { create(:auction, league: league, number: 2, deadline: (Auction::HOURS_FOR_SALES + 24).hours.from_now) }

    it { expect(opener.call).to be(false) }

    it 'does not call Auctions::Manager' do
      opener.call
      expect(Auctions::Manager).not_to have_received(:call)
    end
  end

  context 'when deadline is within HOURS_FOR_SALES' do
    it { expect(opener.call).to be(true) }

    it 'calls Auctions::Manager with SALES_STATUS' do
      opener.call
      expect(Auctions::Manager).to have_received(:call).with(auction, Auctions::Manager::SALES_STATUS)
    end
  end

  context 'when deadline is exactly HOURS_FOR_SALES away' do
    let(:auction) { create(:auction, league: league, number: 2, deadline: Auction::HOURS_FOR_SALES.hours.from_now) }

    it { expect(opener.call).to be(true) }
  end
end

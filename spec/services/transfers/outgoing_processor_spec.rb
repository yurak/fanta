# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transfers::OutgoingProcessor do
  subject(:processor) { described_class.new(league) }

  let(:league) { create(:active_league) }

  before do
    allow(Transfers::Seller).to receive(:call)
    allow(Auctions::Manager).to receive(:call)
  end

  context 'when league has no sales auction' do
    it { expect(processor.call).to be(false) }

    it 'does not call Auctions::Manager' do
      processor.call
      expect(Auctions::Manager).not_to have_received(:call)
    end
  end

  context 'when sales auction has no deadline' do
    before { create(:auction, league: league, status: :sales, deadline: nil) }

    it { expect(processor.call).to be(false) }
  end

  context 'when sales auction deadline is in the future' do
    before { create(:auction, league: league, status: :sales, deadline: 1.hour.from_now) }

    it { expect(processor.call).to be(false) }

    it 'does not call Auctions::Manager' do
      processor.call
      expect(Auctions::Manager).not_to have_received(:call)
    end
  end

  context 'when sales auction deadline has passed' do
    let(:auction) { create(:auction, league: league, status: :sales, deadline: 1.hour.ago) }

    before { auction }

    it { expect(processor.call).to be(true) }

    it 'calls Auctions::Manager with auction and league auction_type' do
      processor.call
      expect(Auctions::Manager).to have_received(:call).with(auction, league.auction_type)
    end

    context 'when a team has transferable players' do
      let(:team) { create(:team, league: league, transfer_slots: 3) }
      let(:striker)  { create(:player) }
      let(:defender) { create(:player) }

      before do
        create(:player_team, player: striker,  team: team, transfer_status: :transferable)
        create(:player_team, player: defender, team: team, transfer_status: :transferable)
      end

      it 'calls Seller for striker' do
        processor.call
        expect(Transfers::Seller).to have_received(:call).with(striker, team, :outgoing)
      end

      it 'calls Seller for defender' do
        processor.call
        expect(Transfers::Seller).to have_received(:call).with(defender, team, :outgoing)
      end

      it 'decrements transfer_slots by the number of transferable players' do
        processor.call
        expect(team.reload.transfer_slots).to eq(1)
      end
    end

    context 'when a team has no transferable players' do
      before { create(:team, league: league) }

      it 'does not call Seller' do
        processor.call
        expect(Transfers::Seller).not_to have_received(:call)
      end
    end

    context 'when a team has untouchable players' do
      let(:team) { create(:team, league: league, transfer_slots: 2) }
      let(:player) { create(:player) }

      before { create(:player_team, player: player, team: team, transfer_status: :untouchable) }

      it 'does not call Seller for untouchable players' do
        processor.call
        expect(Transfers::Seller).not_to have_received(:call)
      end

      it 'does not change transfer_slots' do
        processor.call
        expect(team.reload.transfer_slots).to eq(2)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe ClubTransfers::RequestBuilder do
  let(:tournament) { create(:tournament) }
  let(:current_club) { create(:club, tournament: tournament) }
  let(:new_club) { create(:club, tournament: tournament) }
  let(:player) { create(:player, club: current_club) }

  def transfer(attrs = {})
    create(:club_transfer, { player: player, tm_transfer_id: 100, upcoming: false,
                             start_date: Time.zone.today - 1 }.merge(attrs))
  end

  describe '.call' do
    context 'when the latest transfer points to a different Mantra club' do
      before { transfer(new_club: new_club, new_club_name: new_club.name) }

      it 'creates a pending request' do
        expect { described_class.call(player) }.to change(ClubTransferRequest.pending, :count).by(1)
      end

      it 'targets the new club' do
        described_class.call(player)
        expect(ClubTransferRequest.last.new_club_id).to eq(new_club.id)
      end

      it 'records the tm_transfer_id' do
        described_class.call(player)
        expect(ClubTransferRequest.last.tm_transfer_id).to eq(100)
      end
    end

    context 'when the latest transfer matches the current club' do
      before { transfer(new_club: current_club, new_club_name: current_club.name) }

      it { expect { described_class.call(player) }.not_to change(ClubTransferRequest, :count) }
    end

    context 'when the player left for a non-Mantra club' do
      before { transfer(new_club: nil, new_club_id: nil, new_club_name: 'Foreign FC', new_tm_club_id: '777') }

      it 'creates a request with no Mantra new_club' do
        described_class.call(player)
        expect(ClubTransferRequest.last).to have_attributes(new_club_id: nil, new_club_name: 'Foreign FC')
      end
    end

    context 'when the player is already in Outside and left for a non-Mantra club' do
      let(:current_club) { create(:club, name: 'Outside', tournament: tournament) }

      before { transfer(new_club: nil, new_club_id: nil, new_club_name: 'Foreign FC') }

      it { expect { described_class.call(player) }.not_to change(ClubTransferRequest, :count) }
    end

    context 'when a request for the same tm_transfer already exists' do
      before do
        transfer(new_club: new_club, new_club_name: new_club.name)
        create(:club_transfer_request, player: player, tm_transfer_id: 100, new_club: new_club,
                                       new_club_name: new_club.name)
      end

      it { expect { described_class.call(player) }.not_to change(ClubTransferRequest, :count) }
    end

    context 'when the newest transfer is an upcoming/future move' do
      before do
        transfer(tm_transfer_id: 100, new_club: new_club, new_club_name: new_club.name, start_date: Time.zone.today - 5)
        transfer(tm_transfer_id: 200, new_club: create(:club, tournament: tournament), new_club_name: 'Future FC',
                 start_date: Time.zone.today + 30, upcoming: true)
      end

      it 'ignores it and uses the latest completed transfer' do
        described_class.call(player)
        expect(ClubTransferRequest.last.tm_transfer_id).to eq(100)
      end
    end

    context 'when the player has no imported transfers' do
      it { expect(described_class.call(player)).to be_nil }
    end
  end
end

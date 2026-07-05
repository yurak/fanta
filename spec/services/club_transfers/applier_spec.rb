require 'rails_helper'

RSpec.describe ClubTransfers::Applier do
  let(:tournament) { create(:tournament) }
  let(:old_club) { create(:club, tournament: tournament) }
  let(:player) { create(:player, club: old_club) }

  describe '.call' do
    context 'when the new club is in our DB' do
      let(:new_club) { create(:club, tournament: tournament) }
      let(:request) { create(:club_transfer_request, player: player, new_club: new_club, new_club_name: new_club.name) }

      before { allow(Players::ClubChanger).to receive(:call).and_return(true) }

      it 'returns :changed' do
        expect(described_class.call(request)).to eq(:changed)
      end

      it 'applies the change via ClubChanger' do
        described_class.call(request)
        expect(Players::ClubChanger).to have_received(:call).with(player: player, new_club_id: new_club.id)
      end

      it 'does not create a club transfer record' do
        expect { described_class.call(request) }.not_to change(ClubTransfer, :count)
      end
    end

    context 'when the player is already in the target club' do
      let(:request) { create(:club_transfer_request, player: player, new_club: old_club, new_club_name: old_club.name) }

      it { expect(described_class.call(request)).to eq(:skipped) }
    end

    context 'when the player is already in Outside and the new club is not in our DB' do
      let(:outside) { create(:club, name: 'Outside', tournament: tournament) }
      let(:player) { create(:player, club: outside) }
      let(:request) { create(:club_transfer_request, player: player, new_club: nil, new_club_name: 'Foreign FC') }

      it { expect(described_class.call(request)).to eq(:skipped) }
    end

    context 'when the player left a real club to a club not in our DB' do
      let!(:outside) { create(:club, name: 'Outside', tournament: tournament) }
      let(:request) { create(:club_transfer_request, player: player, new_club: nil, new_club_name: 'Foreign FC') }

      before { allow(Players::ClubChanger).to receive(:call).and_return(true) }

      it 'returns :changed' do
        expect(described_class.call(request)).to eq(:changed)
      end

      it 'moves the player to Outside' do
        described_class.call(request)
        expect(Players::ClubChanger).to have_received(:call).with(player: player, new_club_id: outside.id)
      end
    end

    context 'when ClubChanger fails' do
      let(:new_club) { create(:club, tournament: tournament) }
      let(:request) { create(:club_transfer_request, player: player, new_club: new_club, new_club_name: new_club.name) }

      before { allow(Players::ClubChanger).to receive(:call).and_return(false) }

      it { expect(described_class.call(request)).to eq(:failed) }
    end
  end
end
